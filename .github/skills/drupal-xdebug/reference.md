# Debugging Drupal con xdebug-mcp y OpenCode

## Resumen

Este proyecto usa **xdebug-mcp** (servidor MCP) para debuggear código PHP de Drupal
desde OpenCode. El setup funciona en **WSL2** con DDEV (Docker) y es compatible con
PHPStorm en Windows simultáneamente.

```
Prerequisitos:
- OpenCode corriendo con MCP xdebug activo (enabled: true en opencode.json)
- Verificar con: las herramientas xdebug_* están disponibles

Workflow en 4 pasos:
0. ddev xdebug on                   → Activar Xdebug temporalmente
1. Configurar pending breakpoints   → En OpenCode (ANTES de ejecutar)
2. ddev drush-xdebug <comando> &    → Ejecutar en background
3. xdebug_continue()                → Breakpoint alcanzado, inspeccionar
4. ddev xdebug off                  → Desactivar Xdebug al terminar
```

---

## Principio de diseño: Xdebug bajo demanda

**Configuración por defecto:**

- `xdebug_enabled: false` en `.ddev/config.yaml`
- Xdebug **DESACTIVADO** → mejor rendimiento, navegador funciona normal
- Se activa **solo cuando vas a debuggear** con `ddev xdebug on`
- Se desactiva cuando terminas con `ddev xdebug off`

**Ventajas:**

- ✅ Sin configuración extra por proyecto (no necesitas `xdebug_host.ini`)
- ✅ Navegador funciona siempre que no estés debuggeando
- ✅ Control explícito de cuándo está activo el debugging
- ✅ Mejor rendimiento cuando no debuggeas

---

## Arquitectura del setup: Puertos separados

```
┌──────────────────────────────────────────────────────────────┐
│  Windows / Mac / WSL2 (cualquier SO)                         │
│  ┌──────────────┐                                            │
│  │  PHPStorm     │ ◄── puerto 9003 (requests web/HTTP)       │
│  │  :9003        │     host.docker.internal                  │
│  └──────────────┘                                            │
├──────────────────────────────────────────────────────────────┤
│  Host local (donde corre OpenCode)                           │
│  ┌──────────────┐                                            │
│  │  OpenCode     │ ◄── puerto 9010 (drush/CLI)               │
│  │  xdebug-mcp   │     172.20.0.1 (Docker bridge gateway)    │
│  │  :9010        │                                           │
│  └──────────────┘                                            │
│         ▲                                                    │
│         │         ┌────────────────────────────┐             │
│         └─────────│  DDEV (Docker)             │             │
│                   │  Xdebug (on-demand)        │             │
│                   │  Override port via -d flag │             │
│                   └────────────────────────────┘             │
└──────────────────────────────────────────────────────────────┘
```

### Cómo conviven PHPStorm y OpenCode (puertos separados)

**Ambos pueden estar activos simultáneamente sin conflictos:**

- **PHPStorm - Puerto 9003 (default)**

  - Escucha en `host.docker.internal:9003`
  - Recibe debugging de requests **web** (navegador, HTTP)
  - Usa la configuración default de DDEV
  - **Funciona en cualquier SO**: Windows, Mac, WSL2

- **OpenCode - Puerto 9010 (custom)**
  - xdebug-mcp escucha en `0.0.0.0:9010` (todas las interfaces)
  - Recibe debugging de comandos **CLI** via `ddev drush-xdebug`
  - `drush-xdebug` fuerza puerto 9010 con `-dxdebug.client_port=9010`
  - **Funciona en cualquier SO**: Windows, Mac, WSL2

**Ventajas:**

- ✅ Ambos debuggers coexisten sin apagarse entre sí
- ✅ PHPStorm para debugging web (navegador)
- ✅ OpenCode para debugging CLI (drush commands)
- ✅ Portable: funciona igual en todos los entornos del equipo
- ✅ No requiere cambiar configuraciones según cuál uses

---

## Archivos de configuración

### `.ddev/config.yaml`

```yaml
xdebug_enabled: false # Desactivado por defecto (activar con ddev xdebug on)
```

> **Importante:** Mantener en `false` para debugging bajo demanda.

### NO necesitas `xdebug_host.ini`

La configuración default de DDEV es suficiente:

- `xdebug.mode=debug,develop`
- `xdebug.client_host=host.docker.internal` (172.26.x.x → PHPStorm en Windows)
- `xdebug.client_port=9003` (default para PHPStorm)
- `xdebug.start_with_request=yes`

`ddev drush-xdebug` sobreescribe `client_host` y `client_port` en cada ejecución para apuntar a xdebug-mcp.

### `opencode.json` (sección xdebug)

```json
{
  "mcp": {
    "xdebug": {
      "type": "local",
      "command": ["npx", "-y", "xdebug-mcp"],
      "environment": {
        "XDEBUG_HOST": "0.0.0.0",
        "XDEBUG_PORT": "9010",
        "PATH_MAPPINGS": "{\"/var/www/html\": \"/home/alex/sites/hiberus/hiberus-d10\"}",
        "COMMAND_TIMEOUT": "60000"
      }
    }
  }
}
```

- **`XDEBUG_HOST: 0.0.0.0`** — escucha en todas las interfaces (necesario para Docker)
- **`XDEBUG_PORT: 9010`** — **puerto dedicado para OpenCode** (9003 es para PHPStorm)
- **`PATH_MAPPINGS`** — mapea rutas del contenedor a rutas del host para breakpoints
- **`COMMAND_TIMEOUT: 60000`** — 60s timeout para operaciones de debug

> **Nota sobre el puerto:** Si el puerto 9010 está ocupado en tu entorno, puedes usar otro puerto libre (ej: 9020, 9030). Asegúrate de actualizar también el archivo `drush-xdebug` con el mismo puerto.

### Comando `drush-xdebug`

Ruta destino: `.ddev/commands/web/drush-xdebug`

Comando custom que:

1. Auto-detecta la IP del Docker bridge gateway
2. Establece `DRUSH_ALLOW_XDEBUG=1`
3. Sobreescribe `xdebug.client_host` y `xdebug.client_port=9010` apuntando a xdebug-mcp
4. Usa `vendor/drush/drush/drush.php` directamente
5. Soporte stdin para `ev` (evita problemas de quoting)

El fichero fuente está en `scripts/drush-xdebug` dentro de la skill. Si no existe en el proyecto, copiarlo desde ahí (ver instrucciones en `SKILL.md`).

---

## Uso: Debugging paso a paso

### Prerequisito: Verificar que xdebug-mcp está activo

**OpenCode debe estar corriendo** con el MCP server de xdebug activo. Esto se configura en `opencode.json`:

```json
{
  "mcp": {
    "xdebug": {
      "enabled": true
    }
  }
}
```

Verificar que las herramientas `xdebug_*` están disponibles en OpenCode. Si no lo están, el MCP no está activo y el debugging no funcionará.

### Preparación: lee el código antes de empezar

Antes de activar xdebug, dedica un momento a leer el método objetivo:

1. **Primera línea ejecutable**: los breakpoints deben ir en sentencias ejecutables, no en firmas de función (`public function foo()`) ni atributos PHP (`#[Alter]`). Pon el breakpoint en la primera línea del cuerpo del método.

2. **Early returns**: si el método tiene guardas al principio (`if (!$this->service) { return; }`), los breakpoints más abajo nunca se alcanzarán. Pon un breakpoint antes de esas guardas o al principio del método.

3. **Comando disponible**: si vas a disparar el debug con un comando drush, verifica que existe:
   ```bash
   ddev drush list | grep <nombre-del-comando>
   ```

### Paso 0: Activar Xdebug

**ANTES de empezar a debuggear**, activar Xdebug:

```bash
ddev xdebug on
```

Verificar que está activo:

```bash
ddev exec "php -m | grep xdebug"
# Debe mostrar: xdebug
```

### Paso 1: Configurar breakpoints pendientes

En OpenCode, configurar breakpoints **ANTES** de ejecutar el código.
Se aplican automáticamente cuando una sesión se conecta.

```
xdebug_set_breakpoint(
  file="/var/www/html/web/modules/custom/mi_modulo/src/MiClase.php",
  line=105
)
```

> **Importante**: Usar rutas del **contenedor** (`/var/www/html/...`).
> PATH_MAPPINGS traduce automáticamente.

### Paso 2: Ejecutar drush en background

```bash
# Eval con código PHP — usar stdin (pipe)
echo '\Drupal::service("mi_servicio")->miMetodo();' | ddev drush-xdebug ev > /tmp/output.log 2>&1 &

# Eval multilínea
cat <<'PHP' | ddev drush-xdebug ev > /tmp/output.log 2>&1 &
$service = \Drupal::service("tool_canvas.content_template_service");
$result = $service->getComponentContext(["enabled_only" => TRUE]);
echo count($result) . " source types\n";
PHP
```

> **¿Por qué background (&)?** — Xdebug pausa el script al conectar. Si se ejecuta
> en foreground, el terminal queda bloqueado.

> **Scripts cortos (< 200ms)**: si el script termina antes de que puedas listar las sesiones, el proceso habrá desconectado y no verás nada en `xdebug_list_sessions()`. En ese caso, construye un script más largo o usa `drush scr` con un script que ejecute el código en un bucle. Ver Troubleshooting.

### Ejemplo: Debuggear un hook de formulario

Los hooks `#[Alter]` de formulario se disparan durante el renderizado web. Desde CLI no hay un formulario real, pero puedes invocar el método del hook directamente con un mock:

```php
cat <<'PHP' | ddev drush-xdebug ev > /tmp/output.log 2>&1 &
// Construir un $form mock con los campos que te interesan
$form = [
  '#id' => 'views-exposed-form-search-block-1',
  'field_country' => ['#type' => 'select', '#options' => []],
];
$form_state = new \Drupal\Core\Form\FormState();

// Invocar el hook directamente via class_resolver (respeta dependencias)
$hooks = \Drupal::service('class_resolver')
  ->getInstanceFromDefinition(\Drupal\mi_modulo\Hooks\MisHooks::class);
$hooks->miMetodoHook($form, $form_state, 'views_exposed_form');
PHP
```

El breakpoint al inicio de `miMetodoHook` se alcanzará y podrás inspeccionar `$form`.

### Paso 3: Esperar sesión y debuggear

```bash
sleep 5  # Esperar a que la sesión conecte
```

En OpenCode:

```
xdebug_list_sessions()        → buscar sesión activa
```

La sesión puede estar en dos estados al conectar:

- **`break`** — xdebug-mcp aplicó los pending breakpoints y avanzó automáticamente. Puedes inspeccionar variables directamente sin llamar `continue`.
- **`starting`** — la sesión está pausada antes de ejecutar. Llama `xdebug_continue()` para avanzar al primer breakpoint.

Siempre comprueba el estado antes de llamar `continue`.

En el breakpoint:

```
xdebug_get_variables()                    → todas las variables locales
xdebug_evaluate("$context")              → valor completo (preferido para strings)
xdebug_evaluate("array_keys($context)")  → inspeccionar estructura
xdebug_evaluate("count($context)")       → contar elementos
xdebug_evaluate("$this->metodo()")       → llamar un método directamente
xdebug_get_variable(name="$obj")         → árbol de propiedades (puede truncar strings)
xdebug_step_over()                       → siguiente línea
xdebug_step_into()                       → entrar en función
xdebug_continue()                        → siguiente breakpoint
```

> **Sobre strings y truncamiento:** `xdebug_get_variable` puede mostrar strings truncados (p.ej. `"vi"` en lugar de `"views-exposed-form-..."`). Usa `xdebug_evaluate("$var")` para obtener el valor completo. `xdebug_evaluate` también es útil para llamar métodos y ver su resultado, incluso sin un breakpoint en la línea de retorno.

### Paso 4: Limpieza y desactivación

Cuando termines de debuggear:

```
# Cerrar sesiones activas (recomendado)
xdebug_close_session(session_id="...")

# Limpiar breakpoints pendientes
xdebug_remove_breakpoint(breakpoint_id="...")
```

**Desactivar Xdebug:**

```bash
ddev xdebug off
```

Verificar que está desactivado:

```bash
ddev exec "php -m | grep xdebug"
# No debe mostrar nada (exit status 1)
```

---

## Quoting: `ddev drush-xdebug ev`

DDEV ejecuta comandos web con `bash -c "..."` que rompe argumentos con paréntesis.

**Solución implementada**: Usar stdin con pipe para `ev`:

```bash
# ✅ FUNCIONA — stdin, sin problemas de quoting
echo 'phpinfo();' | ddev drush-xdebug ev
echo '\Drupal::service("foo")->bar();' | ddev drush-xdebug ev

# ❌ FALLA — paréntesis en argumento directo
ddev drush-xdebug ev 'phpinfo();'
```

Cuando `ev` recibe stdin, el comando escribe el código en un archivo temporal con
`<?php` y usa `drush scr` en vez de `drush ev`.

---

## Cómo funciona (protocolo DBGp)

1. `ddev xdebug on` → activa Xdebug en PHP
2. Script PHP inicia → Xdebug conecta a xdebug-mcp (puerto 9010)
3. Sesión entra en estado `starting` → **script PAUSADO**, no ejecuta nada
4. xdebug-mcp aplica breakpoints pendientes automáticamente
5. `continue` → el script ejecuta hasta el primer breakpoint
6. Xdebug pausa en el breakpoint → estado `break` → inspección de variables
7. `ddev xdebug off` → desactiva Xdebug, navegador vuelve a funcionar

**No se necesita `sleep()` ni `xdebug_break()`** en el código fuente.

---

## Por qué no usar `xdebug_enabled: true` permanente

Con `xdebug_enabled: true` en `.ddev/config.yaml`:

- ❌ Xdebug siempre activo → impacto en rendimiento
- ❌ Cada request web intenta conectar al debugger
- ❌ Si xdebug-mcp está escuchando, el navegador se congela (sesiones en `starting`)
- ❌ Necesitas configurar `xdebug.start_with_request=trigger` + extensión de navegador

Con `xdebug_enabled: false` + `ddev xdebug on` bajo demanda:

- ✅ Xdebug solo activo cuando debuggeas
- ✅ Navegador funciona normal el resto del tiempo
- ✅ Sin configuración extra (`xdebug_host.ini` innecesario)
- ✅ Control explícito de cuándo está activo

---

## Troubleshooting

### El MCP de xdebug no arranca / se desactiva automáticamente

**Causa:** El puerto 9010 está ocupado por otro proceso.

**Diagnóstico:**

```bash
# Verificar si el puerto está libre
ss -tlnp | grep 9010

# Si está ocupado, ver qué proceso lo usa
sudo lsof -i:9010
```

**Solución:**

**Opción A:** Liberar el puerto 9010

```bash
# Identificar y matar el proceso
sudo lsof -i:9010
sudo kill -9 <PID>
```

**Opción B:** Usar otro puerto libre

```bash
# Verificar puertos libres
ss -tlnp | grep -E ':(9020|9030|9040)'

# Si 9020 está libre, cambiar en 2 lugares:
# 1. opencode.json → "XDEBUG_PORT": "9020"
# 2. .ddev/commands/web/drush-xdebug → -dxdebug.client_port=9020

# Reiniciar OpenCode para aplicar cambios
```

**Opción C:** Configurar firewall (solo si es necesario)

```bash
# En algunos entornos puede ser necesario abrir el puerto
sudo iptables -I INPUT -p tcp --dport 9010 -j ACCEPT
```

### No se conecta la sesión

```bash
# 1. Verificar que Xdebug está activo
ddev exec "php -m | grep xdebug"

# 2. Activar si está desactivado
ddev xdebug on

# 3. Verificar configuración
ddev exec "php -i | grep xdebug.client"

# 4. Verificar que xdebug-mcp está escuchando en puerto 9010
ss -tlnp | grep 9010
# Debe mostrar un proceso node escuchando

# 5. Verificar gateway IP (para drush-xdebug)
ddev exec "ip route | grep default"
```

### El navegador no carga (se queda esperando)

**Causa:** Xdebug está activo y hay una sesión web esperando comandos.

**Solución inmediata:**

```bash
# Opción 1: Desactivar Xdebug
ddev xdebug off

# Opción 2: Cerrar sesiones huérfanas en OpenCode
xdebug_list_sessions()
xdebug_close_session(session_id="...")
```

### Sesiones huérfanas

```
xdebug_list_sessions()                    → ver sesiones activas
xdebug_close_session(session_id="...")    → cerrar sesión específica
```

### El breakpoint no se alcanza

- Verificar que el archivo y línea son correctos (ruta del contenedor)
- Verificar que el código realmente ejecuta esa línea
- **Buscar early returns**: si el método tiene una guarda (`if (!$service) { return; }`) antes de tu breakpoint, el código nunca llegará. Pon el breakpoint en la línea de la guarda o antes de ella.
- **Línea no ejecutable**: las firmas de función (`public function foo()`) y atributos PHP (`#[Alter]`) no son ejecutables. Pon el breakpoint en la primera sentencia del cuerpo.
- Verificar que Xdebug está activo: `ddev exec "php -m | grep xdebug"`
- Verificar que el breakpoint fue aplicado: `xdebug_list_breakpoints()`

### El script termina antes de que puedas listar la sesión (scripts cortos)

**Síntoma:** `xdebug_list_sessions()` no muestra sesiones aunque el comando drush se ejecutó.

**Causa:** El script completa en < 200ms — menos que el `sleep 5`. La sesión xdebug se conecta, ejecuta y desconecta antes de que puedas interactuar.

**Soluciones:**

1. **Añade un breakpoint al inicio del método** — xdebug pausará el script en la primera línea antes de que pueda terminar, dándote tiempo.

2. **Usa un script más complejo** que haga más trabajo y tarde más tiempo (por ejemplo, `ddev drush-xdebug cr` tarda varios segundos).

3. **Verifica que el breakpoint está en código que realmente se ejecuta** — si hay un early return antes, el script termina rápido sin detenerse.

---

## Referencia rápida

| Acción                              | Comando                                                          |
| ----------------------------------- | ---------------------------------------------------------------- |
| Activar Xdebug                      | `ddev xdebug on`                                                 |
| Desactivar Xdebug                   | `ddev xdebug off`                                                |
| Verificar estado                    | `ddev exec "php -m \| grep xdebug"`                              |
| Ver comandos drush                  | `ddev drush list \| grep <nombre>`                               |
| Poner breakpoint                    | `xdebug_set_breakpoint(file="/var/www/html/...", line=N)`        |
| Ejecutar drush                      | `ddev drush-xdebug <cmd> > /tmp/out.log 2>&1 &`                  |
| Eval PHP                            | `echo 'codigo();' \| ddev drush-xdebug ev > /tmp/out.log 2>&1 &` |
| Esperar sesión                      | `sleep 5 && xdebug_list_sessions()`                              |
| Continuar                           | `xdebug_continue()`                                              |
| Variables (scope completo)          | `xdebug_get_variables()`                                         |
| Evaluar expresión / string completo | `xdebug_evaluate("$var")` ← preferido, no trunca                 |
| Árbol de propiedades                | `xdebug_get_variable(name="$obj")`                               |
| Stack trace                         | `xdebug_get_stack_trace()`                                       |
| Step over                           | `xdebug_step_over()`                                             |
| Step into                           | `xdebug_step_into()`                                             |
| Cerrar sesión                       | `xdebug_close_session(session_id="...")`                         |
| Limpiar breakpoint                  | `xdebug_remove_breakpoint(breakpoint_id="...")`                  |

---

Última actualización: 2026-02-13
