---
description: Generar un test JMeter de tráfico autenticado (backoffice Drupal) a partir de los listados de contenido de uno o varios menús.
argument-hint: [menu-id] [menu-id-2 ...]
---

$ARGUMENTS


# Generador de test JMeter — tráfico privado autenticado

Eres un especialista en pruebas de carga JMeter para proyectos Drupal. Tu tarea es generar un fichero `.jmx` de tráfico autenticado (backoffice) y un bloque de documentación `README.md` a partir de los ítems de uno o varios menús de Drupal del backoffice, siguiendo exactamente la misma estructura que `tests/jmeter/private_workflow.jmx`.

---

## Argumentos

Los IDs de menú de Drupal son:

<menu-ids>
$ARGUMENTS
</menu-ids>

Si no se proporciona ningún ID de menú, detente inmediatamente y muestra al usuario:

```
Error: debes proporcionar al menos un ID de menú de Drupal como argumento.
Ejemplo: /jmeter:create-private-test organization-chart-management-me
```

---

## Proceso

### Paso 1 — Obtener los ítems de cada menú

Para cada ID de menú proporcionado, ejecuta este comando para obtener todos sus ítems con título y ruta:

```bash
ddev drush php:eval "
\$menu_id = '<MENU_ID>';
\$menu_tree = \Drupal::menuTree();
\$params = new \Drupal\Core\Menu\MenuTreeParameters();
\$params->setMaxDepth(10);
\$tree = \$menu_tree->load(\$menu_id, \$params);
\$manipulators = [
  ['callable' => 'menu.default_tree_manipulators:generateIndexAndSort'],
  ['callable' => 'menu.default_tree_manipulators:flatten'],
];
\$tree = \$menu_tree->transform(\$tree, \$manipulators);
foreach (\$tree as \$key => \$item) {
  \$link = \$item->link;
  \$url = \$link->getUrlObject()->toString();
  \$title = \$link->getTitle();
  echo \$title . ' | ' . \$url . PHP_EOL;
}
"
```

(Sustituye `<MENU_ID>` por el ID real del menú en cada ejecución.)

Si algún menú no existe o está vacío, informa al usuario y continúa con los demás.

### Paso 2 — Mostrar los ítems y preguntar al usuario qué incluir

Presenta al usuario la lista completa de ítems obtenidos (título + ruta) agrupados por menú, e indica:

- Qué URLs son rutas del backoffice admin (empiezan por `/admin/`) — **éstas son las candidatas a listados de contenido**
- Qué URLs no son rutas admin o son externas — se ignorarán automáticamente

Pregunta al usuario:

1. **¿Cuántos listados quiere incluir en el flujo?** (o confirmar "todos")  
   Puede indicar un número (los N primeros ítems admin de la lista) o seleccionar por número de línea.

Espera la respuesta del usuario antes de continuar.

**No preguntes ni intentes inferir el `form_id` de cada tipo de nodo.** El test captura el `form_id` dinámicamente de la respuesta HTTP del formulario de edición (igual que captura `form_build_id` y `form_token`), usando un regex genérico. No se necesita conocer el bundle del nodo de antemano.

### Paso 3 — Determinar nombre del test y fichero de salida

El nombre del test se construye a partir de los IDs de menú proporcionados:

- Si es un único menú: `{menu-id}`
- Si son varios: `{menu-id-1}_{menu-id-2}` (concatenados con `_`)

- Fichero JMX: `tests/jmeter/{nombre-test}_workflow.jmx`
- Bloque README: se añadirá al `tests/jmeter/README.md` existente o se creará `tests/jmeter/{nombre-test}_README.md`

Confirma las rutas con el usuario antes de escribir.

### Paso 4 — Derivar los identificadores de cada listado

Para cada listado seleccionado, necesitas calcular:

- **`slug`**: slug kebab-case descriptivo derivado de la ruta del listado (ej: `/admin/content/organizations` → `organismos`, `/admin/content/registration-offices` → `oficinas-registro`)
- **`prefijo`**: prefijo camelCase para las variables JMeter, derivado del slug (ej: `organismo`, `oficina`, `contInfo`)
- **`varEditUrl`**: nombre de la variable de extracción de URLs de edición, siempre `{prefijo}EditUrl` (ej: `organismoEditUrl`, `oficinaEditUrl`)
- **`varCurrent`**: nombre de la variable de iteración del ForEach, siempre `current{Prefijo}EditUrl` (ej: `currentOrganismoEditUrl`, `currentOficinaEditUrl`)
- **`varPrefix`**: prefijo de las variables de formulario, igual que `prefijo` (ej: `organismo`, `oficina`)
- **`listPath`**: ruta del listado (ej: `/admin/content/organizations`)
- **`refererAnterior`**: ruta del listado anterior (para el header Referer del GET de lista), o `/admin` para el primer listado

El **índice de sampler** (`NN`) es global y se incrementa por cada sampler generado (GET lista, GET edición, POST edición), en grupos de 3 por listado (más 2 para login + 1 para logout). El primer listado empieza con el sampler `NN=01`.

Convención de numeración de samplers (igual que en `private_workflow.jmx`):

```
login-01-GET-formulario
login-02-POST-credenciales
{slug}-01-GET-lista-{tipo}       ← NN relativo dentro del grupo del menú
{slug}-02-GET-edicion-{tipo}
{slug}-03-POST-guardar-{tipo}
{slug}-04-GET-lista-{tipo2}      ← si hay un segundo tipo en el mismo menú
...
logout-01-GET-cerrar-sesion
```

### Paso 5 — Generar el fichero JMX

Lee el fichero `tests/jmeter/private_workflow.jmx` como referencia estructural exacta. El JMX generado debe reproducir fielmente su estructura XML, con estas variantes:

1. El `testname` del `TestPlan` debe ser: `Test Plan - Flujo Privado {Nombre descriptivo}`
2. El `testname` del `ThreadGroup` debe ser: `Trafico privado - {descripcion-del-test}`
3. El comentario del `TestPlan` debe documentar los menús incluidos y el flujo
4. El `ResultCollector` debe usar: `${__P(ficheroResultados,${__time(yyyyMMdd_HHmmss)}_{nombre-test}_results.jtl)}`
5. Los bloques de contenido (uno por listado seleccionado) deben seguir exactamente el patrón del JMX de referencia:

#### Patrón de bloque por listado

```xml
<!-- Lista: {Titulo descriptivo} -->
<HTTPSamplerProxy ... testname="{slug}-NN-GET-lista-{tipo}" ...>
  <stringProp name="HTTPSampler.path">{listPath}</stringProp>
  <stringProp name="HTTPSampler.method">GET</stringProp>
  ...
</HTTPSamplerProxy>
<hashTree>
  <HeaderManager testname="Referer - lista {tipo}">
    <!-- Referer = ruta del listado anterior (o /admin para el primero) -->
    <elementProp name="Referer">
      <stringProp name="Header.value">${__P(protocolo)}://${__P(nServidor)}{refererAnterior}</stringProp>
    </elementProp>
  </HeaderManager>
  <hashTree/>
  <RegexExtractor testname="Extractor - URLs edicion {tipo} (todas)">
    <stringProp name="RegexExtractor.refname">{varEditUrl}</stringProp>
    <stringProp name="RegexExtractor.regex">href="(/node/\d+/edit[^"]*)"</stringProp>
    <stringProp name="RegexExtractor.match_no">-1</stringProp>
    ...
  </RegexExtractor>
  <hashTree/>
  <JSR223PreProcessor testname="Limitar {varEditUrl} a nEdiciones">
    <!-- script Groovy que cap matchNr a nEdiciones, igual que en private_workflow.jmx -->
    <!-- sustituir {varEditUrl} por el nombre real en cada aparición del script -->
  </JSR223PreProcessor>
  <hashTree/>
</hashTree>

<ForeachController testname="ForEach - Edicion {tipo}">
  <stringProp name="ForeachController.inputVal">{varEditUrl}</stringProp>
  <stringProp name="ForeachController.returnVal">{varCurrent}</stringProp>
  <stringProp name="ForeachController.endIndex">${{varEditUrl}_matchNr}</stringProp>
</ForeachController>
<hashTree>
  <!-- GET formulario edicion -->
  <HTTPSamplerProxy testname="{slug}-NN-GET-edicion-{tipo}">
    <stringProp name="HTTPSampler.path">${{varCurrent}}</stringProp>
    ...
  </HTTPSamplerProxy>
  <hashTree>
    <HeaderManager testname="Referer - edicion {tipo}">
      <!-- Referer = listPath del listado actual -->
    </HeaderManager>
    <hashTree/>
    <RegexExtractor testname="Extractor - form_build_id {tipo}">
      <stringProp name="RegexExtractor.refname">{varPrefix}_form_build_id</stringProp>
      <stringProp name="RegexExtractor.regex">name="form_build_id"\s+value="([^"]+)"</stringProp>
      <stringProp name="RegexExtractor.match_no">1</stringProp>
    </RegexExtractor>
    <hashTree/>
    <RegexExtractor testname="Extractor - form_token {tipo}">
      <stringProp name="RegexExtractor.refname">{varPrefix}_form_token</stringProp>
      <stringProp name="RegexExtractor.regex">name="form_token"\s+value="([^"]+)"</stringProp>
      <stringProp name="RegexExtractor.match_no">1</stringProp>
    </RegexExtractor>
    <hashTree/>
    <RegexExtractor testname="Extractor - form_id {tipo}">
      <stringProp name="RegexExtractor.refname">{varPrefix}_form_id</stringProp>
      <stringProp name="RegexExtractor.regex">name="form_id"\s+value="([^"]+)"</stringProp>
      <stringProp name="RegexExtractor.default">FORM_ID_NOT_FOUND</stringProp>
      <stringProp name="RegexExtractor.match_no">1</stringProp>
    </RegexExtractor>
    <hashTree/>
  </hashTree>

  <!-- POST guardar sin cambios -->
  <HTTPSamplerProxy testname="{slug}-NN-POST-guardar-{tipo}">
    <stringProp name="HTTPSampler.path">${{varCurrent}}</stringProp>
    <stringProp name="HTTPSampler.method">POST</stringProp>
    <!-- Argumentos: form_build_id, form_token, form_id, op=Guardar -->
    ...
  </HTTPSamplerProxy>
  <hashTree>
    <HeaderManager testname="Referer - POST guardar {tipo}">
      <!-- Referer = ${__P(protocolo)}://${__P(nServidor)}${{varCurrent}} -->
      <!-- Content-Type = application/x-www-form-urlencoded -->
    </HeaderManager>
    <hashTree/>
  </hashTree>
</hashTree>
```

#### Bloque LOGIN (siempre primero, idéntico al de referencia)

Usa exactamente los mismos samplers `login-01-GET-formulario` y `login-02-POST-credenciales` del fichero de referencia.

#### Bloque LOGOUT (siempre al final, idéntico al de referencia)

El sampler `logout-01-GET-cerrar-sesion` lleva Referer apuntando al **último listado** del flujo.

#### Infraestructura global (idéntica al fichero de referencia)

Copia sin modificar:

- `ResultCollector` (ajustando sólo el nombre del fichero de resultados)
- `ConfigTestElement` (HTTP Request Defaults)
- `HeaderManager` global
- `ResponseAssertion` global
- `DurationAssertion` global
- `CacheManager` + `JSR223PreProcessor` de limpiarCache
- `CookieManager` (con `clearEachIteration=false` — **CRÍTICO para sesión Drupal**)
- `GaussianRandomTimer`

**Importante:** Verifica que todos los `<hashTree>` estén correctamente balanceados antes de escribir el fichero. Cuenta las aperturas y cierres.

### Paso 6 — Generar la documentación

Genera una sección de documentación Markdown con la misma estructura que el `README.md` existente en `tests/jmeter/`. La sección debe incluir:

- Título y descripción del flujo (menús y tipos de contenido cubiertos)
- Tabla de parámetros obligatorios (igual que la tabla del README existente, añadiendo `drupalUser`, `drupalPass` y `nEdiciones`)
- Parámetro opcional `ficheroResultados`
- Comando de ejecución de ejemplo completo con todos los `-J`
- Perfiles de prueba (smoke, carga ligera, carga realista, sin caché)
- Tabla de URLs del flujo (número, sampler testname, ruta)

Pregunta al usuario si quiere:

1. Añadir la documentación al `tests/jmeter/README.md` existente como una nueva sección
2. Crear un fichero separado `tests/jmeter/{nombre-test}_README.md`

---

## Parámetros CLI del test generado

El test generado debe soportar exactamente estos parámetros (los mismos que `private_workflow.jmx`):

| Parámetro           | Ejemplo                | Descripción                                                              |
| ------------------- | ---------------------- | ------------------------------------------------------------------------ |
| `nServidor`         | `gobcan.ddev.site`     | Hostname del servidor bajo prueba                                        |
| `protocolo`         | `https`                | Protocolo HTTP o HTTPS                                                   |
| `nPuerto`           | `443`                  | Puerto (443 para HTTPS, 80 para HTTP)                                    |
| `nHilos`            | `1`                    | Número de usuarios virtuales concurrentes                                |
| `pSubida`           | `1`                    | Tiempo de ramp-up en segundos                                            |
| `nIteraciones`      | `3`                    | Iteraciones completas del flujo por usuario                              |
| `nEdiciones`        | `3`                    | Máximo de nodos a editar por tipo de contenido en cada pasada            |
| `despRetardo`       | `1000`                 | Desplazamiento central del timer gaussiano en ms                         |
| `desvRetardo`       | `500`                  | Desviación estándar del timer gaussiano en ms                            |
| `umbralDuracion`    | `30000`                | Tiempo máximo de respuesta aceptable en ms (SLA)                         |
| `limpiarCache`      | `false`                | `true` para limpiar la caché HTTP entre iteraciones                      |
| `drupalUser`        | `admin`                | Usuario de Drupal con permisos de edición de contenido                   |
| `drupalPass`        | `admin`                | Contraseña del usuario de Drupal                                         |
| `ficheroResultados` | _(auto con timestamp)_ | Ruta del fichero JTL de resultados (opcional, se genera automáticamente) |

---

## Plantilla README — sección a generar

Para cada test generado, produce una sección Markdown con esta estructura:

````markdown
## Escenario N: Tráfico privado — {nombre-test} (`{nombre-test}_workflow.jmx`)

Flujo autenticado: simula un editor del backoffice que recorre {N} listados de contenido
({tipos de contenido}) y entra a editar (sin modificar) hasta `nEdiciones` nodos por tipo.

Menús cubiertos: {lista de menu-ids}.

---

### Requisitos previos

- JMeter 5.6+ instalado
- El entorno objetivo arrancado y accesible
- Un usuario de Drupal con permisos de edición de los tipos de contenido del flujo

---

### Ejecución

#### Comando completo

```bash
/path/to/jmeter/bin/jmeter -n \
  -t tests/jmeter/{nombre-test}_workflow.jmx \
  -JnServidor=gobcan.ddev.site \
  -Jprotocolo=https \
  -JnPuerto=443 \
  -JnHilos=1 \
  -JpSubida=1 \
  -JnIteraciones=3 \
  -JnEdiciones=3 \
  -JdespRetardo=1000 \
  -JdesvRetardo=500 \
  -JumbralDuracion=30000 \
  -JlimpiarCache=false \
  -JdrupalUser=admin \
  -JdrupalPass=admin \
  -l tests/jmeter/results.jtl \
  -e -o tests/jmeter/report
```

#### Parámetros obligatorios

| Parámetro        | Ejemplo            | Descripción                                               |
| ---------------- | ------------------ | --------------------------------------------------------- |
| `nServidor`      | `gobcan.ddev.site` | Hostname del servidor bajo prueba                         |
| `protocolo`      | `https`            | Protocolo HTTP o HTTPS                                    |
| `nPuerto`        | `443`              | Puerto (443 para HTTPS, 80 para HTTP)                     |
| `nHilos`         | `1`                | Número de usuarios virtuales concurrentes                 |
| `pSubida`        | `1`                | Tiempo de ramp-up en segundos                             |
| `nIteraciones`   | `3`                | Iteraciones completas del flujo por usuario               |
| `nEdiciones`     | `3`                | Máximo de nodos a editar por tipo de contenido por pasada |
| `despRetardo`    | `1000`             | Desplazamiento central del timer gaussiano en ms          |
| `desvRetardo`    | `500`              | Desviación estándar del timer gaussiano en ms             |
| `umbralDuracion` | `30000`            | Tiempo máximo de respuesta aceptable en ms (SLA)          |
| `limpiarCache`   | `false`            | `true` para limpiar caché HTTP entre iteraciones          |
| `drupalUser`     | `admin`            | Usuario de Drupal con permisos de edición                 |
| `drupalPass`     | `admin`            | Contraseña del usuario de Drupal                          |

#### Parámetro opcional: `ficheroResultados`

El `ResultCollector` embebido escribe automáticamente un fichero con timestamp:

```
20260302_154532_{nombre-test}_results.jtl
```

Para sobrescribir la ruta:

```bash
-JficheroResultados=/ruta/personalizada/mi_test.jtl
```

#### Perfiles de prueba habituales

**Humo (smoke)** — verificar que el flujo de login/edición/logout funciona sin errores:

```bash
-JnHilos=1 -JpSubida=1 -JnIteraciones=1 -JnEdiciones=1 -JdesvRetardo=0 -JdespRetardo=0
```

**Carga ligera** — referencia de rendimiento en local/preproducción:

```bash
-JnHilos=3 -JpSubida=9 -JnIteraciones=3 -JnEdiciones=3 -JdesvRetardo=2000 -JdespRetardo=500
```

**Carga realista** — simular editores concurrentes con pausas naturales:

```bash
-JnHilos=10 -JpSubida=30 -JnIteraciones=5 -JnEdiciones=5 -JdesvRetardo=5000 -JdespRetardo=1000
```

**Sin caché** — peor caso: todos los usuarios con caché vacía:

```bash
-JlimpiarCache=true -JnHilos=5 -JpSubida=15 -JnIteraciones=3 -JnEdiciones=3
```

---

### Listados del flujo ({N} bloques de edición)

| #   | Menú origen | Sampler GET lista | Ruta del listado |
| --- | ----------- | ----------------- | ---------------- |

{TABLA_LISTADOS}
````

---

## Notas adicionales

- Usa las herramientas Read, Write y Bash para escribir los ficheros generados.
- El JMX debe ser XML válido — verifica que todos los `<hashTree>` estén balanceados antes de escribir.
- Si una ruta no empieza por `/admin/`, omítela del flujo autenticado y avisa al usuario.
- Si hay rutas duplicadas entre menús, omite los duplicados y avisa al usuario.
- No incluyas URLs externas (que no empiecen por `/`).
- El `CookieManager` debe tener `clearEachIteration=false` — es **crítico** para que la sesión de Drupal se mantenga entre requests dentro de la misma iteración.
- El groovy script de `limpiarCache` usa `ctx.getSamplerContext()` — cópialo exactamente del fichero de referencia.
- El XML debe seguir la misma indentación (2 espacios) que el fichero de referencia.
