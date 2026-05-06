---
description: Generar un test JMeter de tráfico anónimo a partir de los items de un menú de Drupal.
argument-hint: [menu-id]
---

$ARGUMENTS


# Generador de test JMeter — tráfico anónimo

Eres un especialista en pruebas de carga JMeter para proyectos Drupal. Tu tarea es generar un fichero `.jmx` de tráfico anónimo y un `README.md` de documentación a partir de los items de un menú de Drupal, siguiendo exactamente la misma estructura que `tests/jmeter/public_workflow.jmx`.

---

## Argumento

El ID del menú de Drupal es:

<menu-id>
$ARGUMENTS
</menu-id>

Si no se proporciona un ID de menú, detente inmediatamente y muestra al usuario:

```
Error: debes proporcionar el ID del menú de Drupal como argumento.
Ejemplo: /jmeter:create-anonymous-test main-navigation
```

---

## Proceso

### Paso 1 — Obtener los items del menú

Ejecuta este comando para obtener todos los items del menú con sus URLs:

```bash
ddev drush php:eval "
\$menu_id = '$ARGUMENTS';
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

Si el menú no existe o no tiene items, muestra un error descriptivo y detente.

### Paso 2 — Preguntar cuántas URLs incluir en el flujo

Presenta al usuario la lista completa de URLs obtenidas (título + ruta) y pregunta cuántas deben formar el flujo de navegación. Recomienda entre 15 y 30 para un test representativo.

El usuario puede:

- Indicar un número (las primeras N URLs de la lista)
- Indicar URLs específicas por número de línea
- Confirmar "todas" para usar la lista completa

Espera la respuesta del usuario antes de continuar.

### Paso 3 — Determinar el nombre del fichero de salida

El nombre del test se deriva del `menu-id`:

- Reemplaza guiones por guiones bajos si es necesario (o mantén el kebab-case)
- Fichero JMX: `tests/jmeter/{menu-id}_workflow.jmx`
- Fichero README: `tests/jmeter/{menu-id}_README.md` (o actualiza el `README.md` existente añadiendo una nueva sección)

Confirma la ruta con el usuario antes de escribir.

### Paso 4 — Construir los samplers

Para cada URL seleccionada (en orden), necesitas:

- **slug**: última parte de la ruta URL, sanitizada (sin `/`, sin caracteres especiales)
- **idx**: índice 1-based del sampler en la secuencia
- **path**: ruta completa (ej. `/temas/administracion-publica/entidades-juridicas`)
- **parent_path**: ruta del sampler inmediatamente anterior (vacío para el primer sampler)

El `testname` del sampler es `{slug}-{idx}` (ej. `entidades-juridicas-2`).

### Paso 5 — Generar el fichero JMX

Usa la plantilla de infraestructura fija (ver más abajo) y sustituye únicamente la sección de samplers con los N samplers generados.

El nombre del `ThreadGroup` debe ser descriptivo: `Trafico anonimo - {menu-id}`.

Escribe el fichero en `tests/jmeter/{menu-id}_workflow.jmx`.

### Paso 6 — Generar documentación

Genera un bloque de documentación Markdown con la estructura de la sección "Escenario 1" del `tests/jmeter/README.md`:

- Tabla de parámetros obligatorios
- Comando de ejecución de ejemplo con los parámetros `-J`
- Perfiles de prueba habituales (smoke, carga ligera, carga realista, sin caché)
- Sección de ficheros de resultados (idéntica al README existente)
- Sección de interpretación de resultados

Pregunta al usuario si quiere:

1. Añadir la documentación al `tests/jmeter/README.md` existente como una nueva sección
2. Crear un fichero separado `tests/jmeter/{menu-id}_README.md`

---

## Plantilla JMX — infraestructura fija

El JMX generado debe tener **exactamente** esta estructura. Solo varía el `testname` del `ThreadGroup` y los samplers:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.4.1">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="Test Plan" enabled="true">
      <stringProp name="TestPlan.comments"></stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments" guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables" enabled="true">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Trafico anonimo - {MENU_ID}" enabled="true">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="Loop Controller" enabled="true">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <stringProp name="LoopController.loops">${__P(nIteraciones)}</stringProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">${__P(nHilos)}</stringProp>
        <stringProp name="ThreadGroup.ramp_time">${__P(pSubida)}</stringProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
        <stringProp name="ThreadGroup.duration"></stringProp>
        <stringProp name="ThreadGroup.delay"></stringProp>
        <boolProp name="ThreadGroup.same_user_on_next_iteration">true</boolProp>
      </ThreadGroup>
      <hashTree>

        <ResultCollector guiclass="ViewResultsFullVisualizer" testclass="ResultCollector" testname="View Results Tree" enabled="true">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class="SampleSaveConfiguration">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
              <message>true</message>
              <threadName>true</threadName>
              <dataType>true</dataType>
              <encoding>false</encoding>
              <assertions>true</assertions>
              <subresults>true</subresults>
              <responseData>false</responseData>
              <samplerData>false</samplerData>
              <xml>false</xml>
              <fieldNames>true</fieldNames>
              <responseHeaders>false</responseHeaders>
              <requestHeaders>false</requestHeaders>
              <responseDataOnError>false</responseDataOnError>
              <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
              <assertionsResultsToSave>0</assertionsResultsToSave>
              <bytes>true</bytes>
              <sentBytes>true</sentBytes>
              <url>true</url>
              <threadCounts>true</threadCounts>
              <idleTime>true</idleTime>
              <connectTime>true</connectTime>
            </value>
          </objProp>
          <stringProp name="filename">${__P(ficheroResultados,${__time(yyyyMMdd_HHmmss)}_results.jtl)}</stringProp>
        </ResultCollector>
        <hashTree/>

        <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults" enabled="true">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" enabled="true">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPSampler.domain">${__P(nServidor)}</stringProp>
          <stringProp name="HTTPSampler.port">${__P(nPuerto)}</stringProp>
          <stringProp name="HTTPSampler.protocol">${__P(protocolo)}</stringProp>
          <stringProp name="HTTPSampler.contentEncoding"></stringProp>
          <stringProp name="HTTPSampler.path"></stringProp>
          <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
        </ConfigTestElement>
        <hashTree/>

        <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP Header Manager - Global" enabled="true">
          <collectionProp name="HeaderManager.headers">
            <elementProp name="Accept-Language" elementType="Header">
              <stringProp name="Header.name">Accept-Language</stringProp>
              <stringProp name="Header.value">es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3</stringProp>
            </elementProp>
            <elementProp name="Upgrade-Insecure-Requests" elementType="Header">
              <stringProp name="Header.name">Upgrade-Insecure-Requests</stringProp>
              <stringProp name="Header.value">1</stringProp>
            </elementProp>
            <elementProp name="DNT" elementType="Header">
              <stringProp name="Header.name">DNT</stringProp>
              <stringProp name="Header.value">1</stringProp>
            </elementProp>
            <elementProp name="Accept-Encoding" elementType="Header">
              <stringProp name="Header.name">Accept-Encoding</stringProp>
              <stringProp name="Header.value">gzip, deflate, br</stringProp>
            </elementProp>
            <elementProp name="User-Agent" elementType="Header">
              <stringProp name="Header.name">User-Agent</stringProp>
              <stringProp name="Header.value">Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36</stringProp>
            </elementProp>
            <elementProp name="Accept" elementType="Header">
              <stringProp name="Header.name">Accept</stringProp>
              <stringProp name="Header.value">text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8</stringProp>
            </elementProp>
          </collectionProp>
        </HeaderManager>
        <hashTree/>

        <ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="Assertion - Sin errores HTTP" enabled="true">
          <collectionProp name="Asserion.test_strings">
            <stringProp name="49586">4\d\d</stringProp>
            <stringProp name="49587">5\d\d</stringProp>
          </collectionProp>
          <stringProp name="Assertion.custom_message">La pagina devolvio un error HTTP 4xx o 5xx</stringProp>
          <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
          <boolProp name="Assertion.assume_success">false</boolProp>
          <intProp name="Assertion.test_type">6</intProp>
        </ResponseAssertion>
        <hashTree/>

        <DurationAssertion guiclass="DurationAssertionGui" testclass="DurationAssertion" testname="Assertion - Tiempo maximo de respuesta" enabled="true">
          <stringProp name="DurationAssertion.duration">${__P(umbralDuracion)}</stringProp>
        </DurationAssertion>
        <hashTree/>

        <CacheManager guiclass="CacheManagerGui" testclass="CacheManager" testname="HTTP Cache Manager" enabled="true">
          <boolProp name="clearEachIteration">false</boolProp>
          <boolProp name="useExpires">true</boolProp>
          <boolProp name="CacheManager.controlledByThread">true</boolProp>
        </CacheManager>
        <hashTree/>
        <JSR223PreProcessor guiclass="TestBeanGUI" testclass="JSR223PreProcessor" testname="Cache - Limpieza parametrizable por iteracion" enabled="true">
          <stringProp name="cacheKey">true</stringProp>
          <stringProp name="filename"></stringProp>
          <stringProp name="parameters"></stringProp>
          <stringProp name="scriptLanguage">groovy</stringProp>
          <stringProp name="script">
// Limpia la cache HTTP del hilo si limpiarCache=true (parametro -JlimpiarCache=true)
def limpiar = props.get("limpiarCache", vars.get("limpiarCache") ?: "false")
if (limpiar?.equalsIgnoreCase("true")) {
    def cacheObj_result = ctx.getSamplerContext()?.get(org.apache.jmeter.protocol.http.control.CacheManager.class.getName())
    if (cacheObj_result instanceof org.apache.jmeter.protocol.http.control.CacheManager) {
        cacheObj_result.clear()
        log.debug("Cache HTTP limpiada al inicio de la iteracion")
    }
}
          </stringProp>
        </JSR223PreProcessor>
        <hashTree/>

        <CookieManager guiclass="CookiePanel" testclass="CookieManager" testname="HTTP Cookie Manager" enabled="true">
          <collectionProp name="CookieManager.cookies"/>
          <boolProp name="CookieManager.clearEachIteration">true</boolProp>
          <boolProp name="CookieManager.controlledByThreadGroup">true</boolProp>
        </CookieManager>
        <hashTree/>

        <GaussianRandomTimer guiclass="GaussianRandomTimerGui" testclass="GaussianRandomTimer" testname="Gaussian Random Timer" enabled="true">
          <stringProp name="ConstantTimer.delay">${__P(despRetardo)}</stringProp>
          <stringProp name="RandomTimer.range">${__P(desvRetardo)}</stringProp>
        </GaussianRandomTimer>
        <hashTree/>

        <!-- ============================================================ -->
        <!-- SAMPLERS: sustituir este bloque con los N samplers generados -->
        <!-- ============================================================ -->

        {SAMPLERS}

      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

### Patrón de cada sampler

**Primer sampler** (sin Referer — `parent_path` vacío):

```xml
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="{slug}-{idx}" enabled="true">
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" enabled="true">
    <collectionProp name="Arguments.arguments"/>
  </elementProp>
  <stringProp name="HTTPSampler.path">{path}</stringProp>
  <stringProp name="HTTPSampler.method">GET</stringProp>
  <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
  <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
  <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
  <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
  <stringProp name="HTTPSampler.connect_timeout"></stringProp>
  <stringProp name="HTTPSampler.response_timeout"></stringProp>
</HTTPSamplerProxy>
<hashTree>
  <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="Referer - {slug}" enabled="true">
    <collectionProp name="HeaderManager.headers">
    </collectionProp>
  </HeaderManager>
  <hashTree/>
</hashTree>
```

**Samplers 2..N** (con Referer apuntando al sampler anterior):

```xml
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="{slug}-{idx}" enabled="true">
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" enabled="true">
    <collectionProp name="Arguments.arguments"/>
  </elementProp>
  <stringProp name="HTTPSampler.path">{path}</stringProp>
  <stringProp name="HTTPSampler.method">GET</stringProp>
  <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
  <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
  <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
  <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
  <stringProp name="HTTPSampler.connect_timeout"></stringProp>
  <stringProp name="HTTPSampler.response_timeout"></stringProp>
</HTTPSamplerProxy>
<hashTree>
  <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="Referer - {slug}" enabled="true">
    <collectionProp name="HeaderManager.headers">
      <elementProp name="Referer" elementType="Header">
        <stringProp name="Header.name">Referer</stringProp>
        <stringProp name="Header.value">${__P(protocolo)}://${__P(nServidor)}{parent_path}</stringProp>
      </elementProp>
    </collectionProp>
  </HeaderManager>
  <hashTree/>
</hashTree>
```

### Regla del slug

El `slug` es el último segmento de la ruta URL:

- `/temas/administracion-publica` → `administracion-publica`
- `/` → `home`
- Si hay colisión de slugs en el mismo test, añade el segmento anterior separado por guión

---

## Plantilla README — sección a generar

Para cada test generado, produce una sección Markdown con esta estructura:

````markdown
# Escenario N: Tráfico anónimo — {menu-id} (`{menu-id}_workflow.jmx`)

Flujo: {N} páginas del menú `{menu-id}`.

---

## Requisitos previos

- JMeter 5.6+ instalado (en este proyecto: `/path/to/jmeter/bin/jmeter`)
- El entorno objetivo arrancado y accesible (DDEV local, preproducción o producción)

---

## Ejecución

### Comando completo

```bash
/path/to/jmeter/bin/jmeter -n \
  -t tests/jmeter/{menu-id}_workflow.jmx \
  -JnServidor=gobcan.ddev.site \
  -Jprotocolo=https \
  -JnPuerto=443 \
  -JnHilos=10 \
  -JpSubida=30 \
  -JnIteraciones=10 \
  -JdespRetardo=0 \
  -JdesvRetardo=5000 \
  -JumbralDuracion=3000 \
  -JlimpiarCache=false \
  -l tests/jmeter/results.jtl \
  -e -o tests/jmeter/report
```
````

### Parámetros obligatorios

Todos los parámetros son obligatorios. Si se omite alguno JMeter lo evaluará como cadena vacía y el test fallará.

| Parámetro        | Ejemplo            | Descripción                                                               |
| ---------------- | ------------------ | ------------------------------------------------------------------------- |
| `nServidor`      | `gobcan.ddev.site` | Hostname del servidor bajo prueba                                         |
| `protocolo`      | `https`            | Protocolo HTTP o HTTPS                                                    |
| `nPuerto`        | `443`              | Puerto (443 para HTTPS, 80 para HTTP)                                     |
| `nHilos`         | `10`               | Número de usuarios virtuales concurrentes                                 |
| `pSubida`        | `30`               | Tiempo de ramp-up en segundos (recomendado: igual a `nHilos × 3`)         |
| `nIteraciones`   | `10`               | Iteraciones completas del flujo por usuario                               |
| `despRetardo`    | `0`                | Desplazamiento central del timer gaussiano en ms                          |
| `desvRetardo`    | `5000`             | Desviación estándar del timer gaussiano en ms                             |
| `umbralDuracion` | `3000`             | Tiempo máximo de respuesta aceptable en ms (SLA)                          |
| `limpiarCache`   | `false`            | `true` para simular usuarios sin caché; `false` para usuarios recurrentes |

### Parámetro opcional: `ficheroResultados`

El `ResultCollector` embebido en el JMX escribe automáticamente un fichero con timestamp:

```
20260302_154532_results.jtl   ← generado automáticamente en el directorio de trabajo
```

Para sobrescribir la ruta:

```bash
-JficheroResultados=/ruta/personalizada/mi_test.jtl
```

El flag `-l` de CLI y el `ResultCollector` son **independientes** y pueden coexistir.

### Perfiles de prueba habituales

**Humo (smoke)** — verificar que el entorno responde sin errores:

```bash
-JnHilos=1 -JpSubida=1 -JnIteraciones=1 -JdesvRetardo=0 -JdespRetardo=0
```

**Carga ligera** — referencia de rendimiento en local/preproducción:

```bash
-JnHilos=5 -JpSubida=15 -JnIteraciones=5 -JdesvRetardo=2000 -JdespRetardo=0
```

**Carga realista** — simular tráfico orgánico con pausas entre páginas:

```bash
-JnHilos=20 -JpSubida=60 -JnIteraciones=10 -JdesvRetardo=5000 -JdespRetardo=1000
```

**Sin caché** — peor caso: todos los usuarios llegan por primera vez:

```bash
-JlimpiarCache=true -JnHilos=10 -JpSubida=30 -JnIteraciones=5
```

---

## URLs del flujo ({N} samplers)

| #   | Sampler testname | Ruta |
| --- | ---------------- | ---- |

{URL_TABLE}

```

---

## Notas adicionales

- Usa herramientas del sistema (Read, Write, Bash) para escribir los ficheros generados.
- Verifica que el JMX producido es XML válido antes de escribirlo (cuenta que todos los `<hashTree>` estén balanceados).
- Si el menú tiene URLs externas (que no empiezan por `/`), omítelas del flujo y avisa al usuario.
- Si una URL ya aparece en la lista (duplicado), omite el duplicado y avisa al usuario.
- El JMX debe escribirse exactamente como XML — sin indentar de forma diferente a la plantilla, sin añadir atributos extra.
```
