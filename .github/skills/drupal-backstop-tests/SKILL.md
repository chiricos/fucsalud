---
name: drupal-backstop-tests
description: |
  Visual regression testing automation with BackstopJS for Drupal sites on DDEV.
  Generates scenarios for menus, components by ID/class/selector, full pages,
  and all pages linked from a menu.

  Use this skill when the user mentions: BackstopJS, Backstop, visual regression,
  compare screenshots, visual testing, or compare PROD vs local.
allowed-tools:
  - run_in_terminal
  - read_file
  - create_file
  - replace_string_in_file
  - multi_replace_string_in_file
  - list_dir
  - file_search
  - grep_search
  - semantic_search
  - get_errors
---

# Drupal BackstopJS Visual Regression — Instrucciones para la IA

## Regla principal

**NUNCA asumas el sitio ni los parámetros. DEBES PREGUNTAR AL USUARIO ANTES DE EMPEZAR.**
**Ante cualquier error o bloqueo: PARAR → REPORTAR → PREGUNTAR al usuario.**

## Flujo interactivo obligatorio

La IA DEBE seguir este flujo de conversación interactivo con el usuario (no intentes adivinar ni usar valores por defecto):

1. **Preguntar el sitio** — Ejecutar `scripts/paso-01-analisis.sh` y mostrar la tabla de sitios detectados **con sus URLs DDEV locales** (del campo `site_urls` en `progress.json`). Pedir al usuario que seleccione uno por alias (ej: `uk`, `de`, `es`). ⚠️ Si el sitio seleccionado no tiene URL DDEV configurada (aparece vacía), PARAR y explicar que es necesario:
   - Añadir el alias a `additional_hostnames` en `.ddev/config.yaml`
   - Añadir el mapeo `$sites['<alias>.ddev.site'] = '<folder>'` en `web/sites/sites.php`
   - Ejecutar `ddev restart` y volver a correr `paso-01-analisis.sh`
2. **Preguntar el tipo de componente** — Preguntar qué quiere testear:
   - `menu` — Un menú de Drupal por su machine name (ej: `main`, `footer`)
   - `menu-pages` — Todas las páginas enlazadas en un menú de Drupal (ej: todas las páginas del menú `main`)
   - `selector` — Un componente por selector CSS (ej: `#block-hero`, `.site-header`, `[data-block="views-latest-news"]`)
   - `page` — Una página completa por ruta (ej: `/about-us`, `/contact`)
3. **Preguntar la referencia del componente**:
   - Para `menu`: el machine name del menú (se listará los disponibles con `drush`)
   - Para `menu-pages`: el machine name del menú (se listará los disponibles con `drush`). La IA extraerá automáticamente todos los enlaces del menú y generará un escenario por cada página.
   - Para `selector`: el selector CSS del componente (ID, clase, atributo, etc.)
   - Para `page`: la ruta relativa de la página
4. **Preguntar la URL base de PRODUCCIÓN** — La URL del sitio en producción para capturar las screenshots de referencia (ej: `https://www.example.com`). La URL local DDEV ya se conoce del paso 1 (`site_urls.<alias>` en `progress.json`).
5. **Ejecutar** las fases de preparación, generación y ejecución. El setup del add-on (`paso-02-setup.sh <site_alias>`) sólo necesita hacerse una vez por proyecto — tras eso sólo se recrea la configuración y se ejecutan los tests.
6. **Mostrar reporte** con los resultados y comandos para re-ejecución futura.

## Reglas técnicas

1. **Solo scripts** — Ejecuta los scripts de `$SKILL_DIR/scripts/`, no comandos sueltos. La FASE 0 de análisis de DOM usa `paso-00-fase0.sh <menu_name> [site_uri]` — este script incluye validación de entrada y ejecuta los comandos de inspección de solo lectura (`drush eval`, `curl | python3`) necesarios para que los scripts posteriores generen selectores correctos.
2. **URLs locales por sitio (Drupal multisite)** — Si el proyecto usa Drupal multisite, cada sitio tiene su propia URL DDEV. SIEMPRE obtener la URL local del sitio desde `progress.json` campo `site_urls.<alias>` (generado por `paso-01-analisis.sh`). **NUNCA usar la URL del proyecto principal** (`<project>.ddev.site`) para un sitio secundario.
   - `paso-01-analisis.sh` detecta URLs activas ejecutando `ddev status` (sección "Project URLs") y cruzando con `web/sites/sites.php`. También verifica si hay alias de drush con `ddev drush sa`.
   - Los sitios en `.ddev/config.yaml → additional_hostnames` que aún no hayan aplicado `ddev restart` aparecen como ⏳ — **ejecutar `ddev restart` antes de continuar**.
   - Ejemplo correcto: `uk` → `https://uk.ddev.site` (NO `https://<project>.ddev.site`)
   - Si un sitio no tiene URL configurada → PARAR y añadir a `.ddev/config.yaml additional_hostnames` + mapear en `web/sites/sites.php` + `ddev restart`.
   - Usar esta URL en: `paso-03-prep-modulos.sh <SITE_URL>`, `paso-04-modelado.sh <type> <ref> <SITE_URL>`, `paso-05-generacion.sh <alias> <model> <PROD_URL> <SITE_URL>`, y todos los comandos `ddev drush --uri=<SITE_URL>`
3. **Todo vía DDEV** — Nunca comandos en el host si pueden ir vía `ddev`. BackstopJS se ejecuta en su propio contenedor dedicado gestionado por el add-on `ddev-backstopjs`. Los comandos son `ddev backstop <env> reference/test/approve` — no `ddev exec npx backstop`.
4. **Respetar Drupal** — Utiliza `drush` para gestionar módulos y configuraciones.
5. **Módulos Bloqueadores** — DEBES verificar si existen módulos que interfieran con las capturas de pantalla (captcha, cookie banners, shield, etc.) y desinstalarlos temporalmente. Utiliza `composer show` para detección exhaustiva.
6. **Cookie Banners** — Además de desinstalar módulos, DEBES generar un script `onReady.js` que cierre/oculte banners de cookies via JS (`eu_cookie_compliance`, `cookiebot`, `OneTrust/cookielaw`, `cookie_consent`, etc.) para evitar que aparezcan en las capturas. Además, DEBES añadir los selectores del banner al campo `hideSelectors` de CADA escenario en `backstop.json` como respaldo (ej: `["#onetrust-banner-sdk", "#onetrust-consent-sdk", ".onetrust-pc-dark-filter"]` para OneTrust, `["#CybotCookiebotDialog"]` para CookieBot, `[".eu-cookie-compliance-banner", "#sliding-popup"]` para EU Cookie Compliance).
7. **Tres Viewports Obligatorios** — SIEMPRE generar escenarios para los tres tamaños (ver “Detección de viewports válidos” para excepciones en el tipo `menu`):
   - Desktop: 1920×1080
   - Tablet: 768×1024
   - Mobile: 375×812
8. **PROD como Referencia** — La URL de producción SIEMPRE se usa como `referenceUrl` en BackstopJS. La URL local de DDEV se usa como `url` (test).
9. **Selectores Flexibles** — El campo `selectors` en BackstopJS acepta cualquier CSS selector válido. Cuando el usuario proporciona un selector (ID, clase, atributo), usarlo directamente. Para `menu`, mapear al selector CSS del bloque de menú en Drupal.
10. **MisMatch Threshold** — Usar `0.1` (0.1%) como umbral por defecto. Informar al usuario que puede ajustarlo.
11. **Desarrollo Iterativo** — DEBES ejecutar `backstop reference` primero, luego `backstop test`, y arreglar si hay problemas antes de reportar éxito.
12. **Cierre y Reporte** — Al finalizar, ejecuta `scripts/paso-07-reporte.sh` y muestra el resumen con los comandos de re-ejecución.
13. **Verificación de Rutas** — El reporte final DEBE contener comandos con rutas VERIFICADAS. DEBES comprobar la ubicación exacta de archivos antes de escribir comandos.
14. **Selector Scoping** — Para componentes específicos (no páginas completas), usar `selectors` de BackstopJS para capturar SOLO el componente, no la página entera. Para páginas completas, usar `selectors: ["document"]`.
15. **Esperar Carga Completa** — El script `onReady.js` DEBE esperar a que las fuentes, imágenes y animaciones CSS se hayan cargado antes de capturar. Usar `document.fonts.ready` y `setTimeout` de seguridad.
16. **Hide Selectors** — Para elementos dinámicos que cambian entre capturas (carousels, animaciones, ads), usar `hideSelectors` o `removeSelectors` en BackstopJS para excluirlos.
17. **Imágenes en LOCAL (stage_file_proxy)** — El entorno local normalmente NO tiene los ficheros subidos (imágenes, documentos) del entorno PROD. Esto provoca diferencias por imágenes faltantes. **Solución**: Primero comprobar si ya está instalado y configurado:
    ```bash
    # 1. Comprobar si ya está instalado
    ddev drush --uri=https://[site].ddev.site pm:list --filter=stage_file_proxy --format=table
    # 2. Si está Enabled, comprobar el origin
    ddev drush --uri=https://[site].ddev.site config:get stage_file_proxy.settings origin
    ```
    Si no está instalado o el origin es incorrecto:
    ```bash
    ddev composer require drupal/stage_file_proxy --no-interaction
    ddev drush --uri=https://[site].ddev.site pm:enable stage_file_proxy -y
    ddev drush --uri=https://[site].ddev.site config:set stage_file_proxy.settings origin "https://[PROD_URL]" -y
    ddev drush --uri=https://[site].ddev.site config:set stage_file_proxy.settings origin_dir "sites/default/files" -y
    ddev drush cr
    ```
    Si `stage_file_proxy` no se puede instalar (problemas de red/SSL), usar `removeSelectors` para eliminar las secciones con contenido gráfico de las capturas, manteniendo el foco en el componente que se testea.
18. **removeSelectors — uso con precaución** — `removeSelectors` elimina elementos del DOM antes de capturar. Uso correcto:
    - **Sí**: En escenarios de `page` o `menu-pages` para quitar widgets dinámicos (chat, ads, carousels).
    - **Sí**: En el escenario `default state` de un menú si se quiere focalizar en el menú cerrado.
    - **NO**: En escenarios con **submenú abierto**. Los submenús expandidos son visualmente pequeños (40-60px). Si se elimina el contenido de la página, el viewport queda en blanco y TODOS los estados de submenú producen screenshots **idénticos** (mismo MD5 hash). El contenido de fondo es necesario para diferenciar visualmente cada estado.

    > ⚠️ **Los selectores son SIEMPRE específicos del proyecto.** DEBES inspeccionar el DOM real (Fase 0) para detectar los selectores reales.

## Tipos de componente soportados

| Tipo | Referencia del usuario | Selector BackstopJS generado | Notas |
|------|----------------------|------------------------------|-------|
| `menu` | Machine name (ej: `main`) | El elemento real del menú detectado en el DOM | Se detecta el theme activo y la estructura responsive real |
| `menu-pages` | Machine name (ej: `main`) | `document` | Genera un escenario por cada página enlazada en el menú. Captura página completa |
| `selector` | CSS selector libre | El mismo selector proporcionado | Acepta `#id`, `.class`, `[data-attr]`, combinaciones |
| `page` | Ruta relativa (ej: `/about`) | `document` | Captura la página completa |

## Estrategia de testing para menús

**Regla fundamental**: Los menús se testean **SIEMPRE desde la homepage**, capturando todos los estados posibles del menú. **NUNCA** se generan escenarios por cada página a la que enlaza el menú.

### FASE 0 — Análisis exhaustivo de la estructura del menú (OBLIGATORIA)

**Antes de generar ningún escenario**, DEBES ejecutar el script de análisis que incluye validación de entrada reforzada por código:

```bash
bash "$SKILL_DIR/scripts/paso-00-fase0.sh" <menu_name> [site_uri]
# Ejemplo:
bash "$SKILL_DIR/scripts/paso-00-fase0.sh" main https://uk.ddev.site
```

El script valida el `menu_name` contra `^[a-z0-9_-]+$` (rechaza inyecciones PHP) y ejecuta las tres inspecciones de solo lectura:
1. **Árbol completo del menú** — vía `drush eval` (niveles, ítems con hijos)
2. **Triggers de submenú en el DOM** — detecta `aria-haspopup`, `data-toggle`, etc.
3. **Clases de visibilidad responsive** — detecta `d-none`, `d-lg-block`, etc. para viewport detection

Registrar del output:
- Número de niveles máximo (L1, L2, L3…)
- Qué ítems de L1 tienen hijos
- Qué ítems de L2 tienen hijos (sub-submenús)
- Etiquetas exactas de todos los ítems con hijos

#### Mecanismos de interacción

Al inspeccionar los triggers detectados por el script, determinar para CADA nivel:

| Patrón encontrado | Mecanismo | Evento necesario | Espera |
|-------------------|-----------|------------------|--------|
| `data-toggle="collapse"` o `data-bs-toggle="collapse"` | Bootstrap accordion/collapse | `click` + waitForSelector(`.collapse.show`) | ~350ms |
| `data-toggle="dropdown"` o `data-bs-toggle="dropdown"` | Bootstrap dropdown | `click` + waitForSelector(`.dropdown-menu.show`) | ~200ms |
| `aria-haspopup="true"` sin toggle | Mega-menu o flyout custom | `hover` (`page.hover()`) o `click` | variable |
| `:hover` CSS puro | CSS hover | `page.hover()` | 0ms (CSS) |
| JS custom | Cualquier patrón | inspeccionar JS del theme | variable |

#### Mapear los selectores para cada nivel

Para cada nivel detectado, registrar:
- **Selector del trigger**: el elemento que abre el nivel (`<a id="main2">`, `<button class="menu-toggle">`, etc.)
- **Selector del contenedor del submenú**: dónde aparecen los hijos (`#main2-submenu`, `.dropdown-menu`, `[data-parent="#accordion"]`)
- **Clase de estado activo**: la clase que indica que está abierto (`.show`, `.open`, `.active`, `.is-open`)
- **¿Es sibling o descendiente?** — crítico para determinar el selector de captura

#### Construir el mapa completo de estados a testear

Con toda esa información, construir una tabla antes de generar el backstop.json:

```
Nivel  | Ítem              | Trigger selector     | Contenedor submenú        | Mecanismo
L1     | Products          | #main-products       | #main-products-menu       | click+collapse
L1     | Services          | #main-services       | #main-services-menu       | click+collapse
L2     | Products > Kits   | #main-products-kits  | #main-products-kits-menu  | hover+CSS
```

**Si algún nivel tiene un mecanismo diferente al resto, DEBES adaptar el `onReady.js` para manejar ambos.**

---

### Estados a capturar

Por cada menú se generan los siguientes escenarios, todos desde la homepage (`/`):
1. **Estado por defecto** — el menú tal como aparece al cargar la página (sin interacción)
2. **Un escenario por cada ítem de L1 que tenga hijos** — abriendo ese submenú
3. **Un escenario por cada ítem de L2 que tenga hijos** — abriendo primero su padre L1, luego el submenú L2
4. **Para L3 y más profundo** — cadena completa de aperturas hasta llegar al nivel deseado

**Límite de combinaciones**: No generar la explosión combinatoria completa. Basta con un escenario por cada submenú único (cada "rama" del árbol), no el producto cartesiano de todas las ramas.

### Detección de viewports válidos — OBLIGATORIO

Antes de generar escenarios, DEBES inspeccionar el DOM real para determinar en qué viewports el menú es visible:
- Buscar clases Bootstrap de visibilidad: `d-none`, `d-lg-block`, `d-md-none`, etc.
- Si el menú desktop está oculto en mobile/tablet, **NO generar escenarios para esos viewports**.
- Si en mobile/tablet hay un **menú diferente** (hamburger, offcanvas, drawer), **NO testear en esos viewports** con este test — es un componente distinto que necesita su propio test.
- Resultado: el test de un menú desktop puede tener SOLO viewport Desktop (1920×1080) si el menú no es visible en los demás.

### Ejemplo de escenarios para distintas profundidades de menú

**Menú de 2 niveles (L1 + submenús L2):**
```
[Desktop 1920] Homepage — estado por defecto
[Desktop 1920] Homepage — Products submenu abierto      (click: #main-products)
[Desktop 1920] Homepage — Services submenu abierto      (click: #main-services)
```

**Menú de 3 niveles (L1 → L2 → L3):**
```
[Desktop 1920] Homepage — estado por defecto
[Desktop 1920] Homepage — Products L2 abierto           (click: #main-products)
[Desktop 1920] Homepage — Products > Kits L3 abierto    (click: #main-products → click: #main-kits)
[Desktop 1920] Homepage — Services L2 abierto           (click: #main-services)
```

### Detección de ítems con submenú

Buscar en el DOM los triggers de submenú a todos los niveles:
- `aria-haspopup="true"`, `aria-expanded`, `data-toggle="collapse"`, `data-toggle="dropdown"`
- `data-bs-toggle`, `data-bs-target`, `href="#submenu-id"` con collapse
- El trigger debe ser el elemento que **activa** la apertura (el `<a>` o `<button>` padre)
- El selector de captura debe ser el contenedor común que incluya TODOS los niveles abiertos

### Regla crítica: submenús como elementos hermanos (siblings)

**Problema frecuente**: Antes de inspeccionar, no asumir que el contenedor del submenú es un hermano del menú principal. En muchos temas Drupal el submenú está anidado como **descendiente** del elemento del menú (comparte el cierre `</header>`), por lo que capturar el selector de header incluye automáticamente los submenús expandidos.

**Verificación obligatoria**: Comparar la posición en bytes del elemento submenú vs el cierre del elemento menú:
```bash
# Si submenu_pos < header_close_pos → es descendiente → usar el selector del header
# Si submenu_pos > header_close_pos → es hermano → necesitas el padre común
ddev exec curl -sk https://[site]/ | python3 -c "
import sys
html = sys.stdin.read()
# Replace 'id=\"HEADER_ID\"' and 'id=\"SUBMENU_ID\"' with the real IDs detected in the DOM
a = html.find('id=\"HEADER_ID\"')
b = html.find('</header>', a)
c = html.find('id=\"SUBMENU_ID\"')
print('INSIDE' if a < c < b else 'SIBLING/OUTSIDE')
"
```

### Regla crítica: headers con position:fixed y altura 0 del contenedor padre

**Problema**: Los headers con `position: fixed` están fuera del flujo del documento. Su contenedor padre (ej: `.z-o-container`) tendrá `height: 0` porque los hijos fixed no contribuyen al flujo. BackstopJS lanzará `Error: Node has 0 height` al intentar capturar el padre.

**Solución**: Usar el elemento fixed directamente como selector de captura. Los elementos `position: fixed` SÍ tienen bounding box y Puppeteer puede capturarlos. Si el submenú es descendiente (verificado con la regla anterior), el elemento fixed lo incluye en su captura.

1. Si el submenú es **descendiente** del header fixed → usar el ID del header directamente (detectado en Fase 0)
2. Si el submenú es **hermano** del header fixed → usar dos selectores separados o JS en onReady.js para quitar `position:fixed` temporalmente

### Regla crítica: estrategia por prioridad para abrir submenús en onReady.js

**Problema**: Los submenús se abren de formas muy distintas según el framework (Bootstrap 3/4/5, Foundation, CSS-only, JS custom). Usar un solo enfoque causa fallos silenciosos — los screenshots salen todos idénticos sin error.

**Solución**: `onReady.js` DEBE implementar una **estrategia por prioridad** que detecte en runtime qué funciona y lo use. Se prueban en orden de fiabilidad:

| Prioridad | Método | Cuándo funciona | Cuándo falla |
|-----------|--------|-----------------|--------------|
| 1. **JS framework API** | `jQuery(target).collapse('show')`, `jQuery(target).dropdown('show')`, Foundation reveal, etc. | Cuando la página carga jQuery + Bootstrap/Foundation JS | Sitios sin jQuery, o JS no ejecutado en headless |
| 2. **DOM manipulation** | Forzar clases CSS + estilos inline | Siempre funciona | Puede no activar transiciones CSS o hijos dependientes |

#### Detección del framework en Fase 0

Durante el análisis del DOM (Fase 0), DEBES detectar qué framework JS está disponible:

```bash
# Detectar jQuery + Bootstrap/Foundation
ddev exec curl -sk https://[site]/ | python3 -c "
import sys, re
html = sys.stdin.read()
if 'jquery' in html.lower(): print('jQuery: YES')
if 'bootstrap' in html.lower(): print('Bootstrap: YES')
if 'data-toggle=' in html: print('Bootstrap version: 4 (data-toggle)')
if 'data-bs-toggle=' in html: print('Bootstrap version: 5 (data-bs-toggle)')
if 'foundation' in html.lower(): print('Foundation: YES')
"
```

Registrar en el mapa de estados:
- `framework`: `bootstrap4`, `bootstrap5`, `foundation`, `custom`, `css-only`
- `hasJQuery`: `true`/`false`
- `collapseAPI`: `jQuery.collapse` / `bootstrap.Collapse` / `none`

#### Campos custom en el scenario JSON

Cada escenario con submenú DEBE tener al menos `submenuTarget` en `custom`:

| Campo | Propósito | Ejemplo |
|-------|-----------|---------|
| `submenuTarget` | Selector del elemento collapse/dropdown/panel a abrir | `"#main2-submenu"` |
| `submenuTrigger` | (Opcional) Selector del trigger para actualizar `aria-expanded` | `"a#main2"` |

Para **1 nivel** (L1 → L2):
```json
"custom": {
  "submenuTarget": "#main2-submenu"
}
```

Para **múltiples niveles** (L1 → L2 → L3+), usar arrays (se abren todos en secuencia):
```json
"custom": {
  "submenuTarget": ["#main2-submenu", "#main2-kits-submenu"]
}
```

#### Patrón estándar para `onReady.js` (universal, por prioridad)

```js
module.exports = async (page, scenario) => {
  // 1. Dismiss cookie banners (adapt selectors per project)
  await page.evaluate(() => {
    // OneTrust
    ['#onetrust-banner-sdk', '#onetrust-consent-sdk', '.onetrust-pc-dark-filter'].forEach(sel => {
      document.querySelectorAll(sel).forEach(el => el.remove());
    });
    const acceptBtn = document.querySelector('#onetrust-accept-btn-handler');
    if (acceptBtn) acceptBtn.click();
    // EU Cookie Compliance
    document.querySelectorAll('.eu-cookie-compliance-banner, #sliding-popup').forEach(el => el.remove());
    // CookieBot
    document.querySelectorAll('#CybotCookiebotDialog').forEach(el => el.remove());
  });

  // 2. Open submenu if specified
  const custom = scenario.custom || {};
  const submenuTarget = custom.submenuTarget;

  if (submenuTarget) {
    const targets = Array.isArray(submenuTarget) ? submenuTarget : [submenuTarget];

    for (const target of targets) {
      // PRIORITY 1: Use JS framework API (most reliable when available)
      const apiOpened = await page.evaluate((sel) => {
        // jQuery + Bootstrap 3/4/5 collapse
        const jq = typeof jQuery !== 'undefined' ? jQuery : (typeof $ !== 'undefined' ? $ : null);
        if (jq && jq.fn && jq.fn.collapse) {
          jq(sel).collapse('show');
          return 'jquery-collapse';
        }
        // jQuery + Bootstrap dropdown
        if (jq && jq.fn && jq.fn.dropdown) {
          jq(sel).dropdown('show');
          return 'jquery-dropdown';
        }
        // Bootstrap 5 native API (no jQuery needed)
        if (typeof bootstrap !== 'undefined') {
          const el = document.querySelector(sel);
          if (el && bootstrap.Collapse) {
            new bootstrap.Collapse(el, { toggle: true });
            return 'bs5-collapse';
          }
          if (el && bootstrap.Dropdown) {
            bootstrap.Dropdown.getOrCreateInstance(el).show();
            return 'bs5-dropdown';
          }
        }
        return null;
      }, target);

      if (!apiOpened) {
        // PRIORITY 2: DOM manipulation fallback
        await page.evaluate((sel) => {
          const el = document.querySelector(sel);
          if (!el) return;
          el.classList.add('show');
          el.classList.remove('collapse'); // remove Bootstrap collapse hiding
          el.style.display = 'block';
          el.style.height = 'auto';
          el.style.overflow = 'visible';
          el.style.visibility = 'visible';
          el.style.opacity = '1';
        }, target);
      }
    }

    // Wait for transitions (Bootstrap default: 350ms)
    await new Promise(r => setTimeout(r, 1000));
  }

  // 3. Wait for fonts + stabilization
  await page.evaluate(() => document.fonts.ready);
  await new Promise(r => setTimeout(r, 500));
};
```

**Por qué la prioridad es JS API → DOM manipulation**:
- El JS API (`jQuery.collapse('show')`) activa las **transiciones CSS del framework**, actualiza automáticamente `aria-expanded`, cierra otros paneles del accordion, y ejecuta event handlers registrados. La altura final es correcta.
- La DOM manipulation directa (forzar clases + estilos) funciona visualmente pero puede dejar el panel con altura incorrecta (ej: 48px en vez del tamaño completo) porque los event listeners del framework no se ejecutan.
- En sitios sin jQuery/Bootstrap JS, la DOM manipulation es el único método disponible y es suficiente.

### Regla crítica: captura viewport SIN removeSelectors para escenarios de submenú

**Problema**: Cuando el header es `position: fixed`, su bounding box NUNCA crece al expandir submenús. Se debe usar `selectors: ["viewport"]` para capturar la pantalla completa.

> ⚠️ **NUNCA usar `removeSelectors` en escenarios con submenú abierto.** Los submenús expandidos ocupan típicamente 40-60px de texto en una pantalla de 1920×1080. Si se elimina el contenido de la página (body, footer, etc.), el viewport queda mayoritariamente en blanco y los submenús son visualmente **indistinguibles** entre sí — todos los screenshots salen con el mismo hash MD5. El contexto visual del contenido de fondo es lo que hace cada estado de submenú **visualmente único** en la captura.

**Solución correcta**:

```json
{
  "label": "Menu — default state",
  "selectors": ["viewport"],
  "hideSelectors": ["#onetrust-banner-sdk"],
  "delay": 3000
}
```
```json
{
  "label": "Menu — Products submenu open",
  "selectors": ["viewport"],
  "hideSelectors": ["#onetrust-banner-sdk"],
  "delay": 3000,
  "custom": {
    "submenuTarget": "#products-submenu"
  }
}
```

**Cuándo SÍ usar `removeSelectors`**: Sólo en escenarios de **estado por defecto** (sin submenú) si se quiere focalizar en el menú cerrado, o en escenarios de `page`/`menu-pages` para quitar widgets dinámicos. Para escenarios con submenú abierto, NUNCA.

**Resultado**: Cada screenshot de submenú muestra la página completa con un submenú diferente desplegado sobre el contenido, creando diferencias visuales claras y detectables entre estados. Las diferencias en el contenido de la página entre PROD y LOCAL se compensan con un `misMatchThreshold` adecuado (0.1% - 5% según el proyecto).

## Estrategia de testing para menu-pages (páginas completas desde un menú)

**Objetivo**: Generar automáticamente un escenario BackstopJS de **página completa** (`selectors: ["document"]`) por cada enlace encontrado en un menú de Drupal. Esto permite testear visualmente TODAS las páginas vinculadas desde un menú específico (ej: `main`, `footer`) con un solo comando.

### Diferencias con el tipo `menu`

| Aspecto | `menu` | `menu-pages` |
|---------|--------|--------------|
| Qué se testea | El componente visual del menú (estados, submenús) | Cada página enlazada en el menú |
| Punto de captura | Homepage (submenús se abren vía DOM) | Cada URL individual del menú |
| Selector | Elemento del menú detectado en Fase 0 (ej: `#header-desktop`, `viewport`) | `document` (página completa) |
| Escenarios generados | 1 default + 1 por submenú con hijos | 1 por cada enlace único en el menú |

### Flujo para `menu-pages`

1. **Obtener el árbol completo del menú** usando `drush`:
   ```bash
   ddev drush --uri=https://[site].ddev.site eval "
   \$menu = \Drupal::menuTree();
   \$params = \$menu->getCurrentRouteMenuTreeParameters('[menu_name]');
   \$params->setMaxDepth(9);
   \$tree = \$menu->load('[menu_name]', \$params);
   \$manipulators = [
     ['callable' => 'menu.default_tree_manipulators:checkAccess'],
     ['callable' => 'menu.default_tree_manipulators:generateIndexAndSort'],
   ];
   \$tree = \$menu->transform(\$tree, \$manipulators);
   function dump_links(\$items, \$depth = 0) {
     foreach (\$items as \$item) {
       \$link = \$item->link;
       \$url = \$link->getUrlObject();
       if (!\$url->isRouted() || \$url->getRouteName() !== '<nolink>') {
         \$path = \$url->toString();
         if (\$path && \$path !== '' && \$path !== '/') {
           echo \$link->getTitle() . '|' . \$path . PHP_EOL;
         }
       }
       if (\$item->subtree) dump_links(\$item->subtree, \$depth + 1);
     }
   }
   dump_links(\$tree);
   "
   ```

2. **Filtrar enlaces válidos**:
   - Excluir enlaces externos (que no empiecen con `/`)
   - Excluir `<nolink>` y `<separator>`
   - Excluir anclas (`#section`)
   - Deduplicar rutas (el mismo path puede aparecer en varios niveles)
   - Mantener el título del enlace para el label del escenario

3. **Generar un escenario por cada enlace**:
   - Label: `[Viewport] [SiteAlias] Page — [Título del enlace] ([ruta])`
   - `url`: URL local DDEV + ruta
   - `referenceUrl`: URL PROD + ruta
   - `selectors`: `["document"]`
   - Tres viewports: Desktop (1920×1080), Tablet (768×1024), Mobile (375×812)
   - `hideSelectors`: Los mismos que para cookie banners
   - `misMatchThreshold`: `0.1` por defecto

4. **Ejemplo de escenario generado**:
   ```json
   {
     "label": "[Desktop 1920] UK Page — About Us (/about-us)",
     "referenceUrl": "https://www.example.com/about-us",
     "url": "https://uk.ddev.site/about-us",
     "selectors": ["document"],
     "hideSelectors": [
       "#onetrust-banner-sdk",
       "#onetrust-consent-sdk",
       ".onetrust-pc-dark-filter"
     ],
     "removeSelectors": [],
     "misMatchThreshold": 0.1,
     "requireSameDimensions": false,
     "delay": 1000
    }
   ```

5. **Delay mayor por defecto**: Las páginas completas necesitan más tiempo de carga que un componente. Usar `delay: 1000` (1 segundo) en lugar de 500ms.

6. **stage_file_proxy**: Es CRÍTICO que `stage_file_proxy` esté configurado para que las imágenes de PROD se descarguen bajo demanda. Sin esto, las diferencias por imágenes faltantes harán que todos los tests fallen.

7. **Elementos dinámicos**: Añadir a `hideSelectors` o `removeSelectors` los elementos que cambian entre PROD y LOCAL:
   - Carousels/sliders con contenido rotativo
   - Fechas "hace X días"
   - Banners promocionales
   - Widgets de terceros (chat, analytics)

### Regla: homepage siempre incluida

Si el menú no contiene un enlace a `/` pero el usuario pide `menu-pages`, añadir la homepage (`/`) como primer escenario automáticamente, ya que es la página principal del sitio.

### Regla: backstop.json ID diferenciado

El `id` del backstop.json para `menu-pages` debe ser: `[site]-menu-pages-[menu_name]` (ej: `uk-menu-pages-main`). Esto evita conflictos con tests de tipo `menu` del mismo menú.

## Fases del Proceso

```
1. Análisis      → Identificar sitios y estructura (scripts/paso-01-analisis.sh)
2. Configuración → Instalar add-on y crear estructura (scripts/paso-02-setup.sh <site_alias>)
3. Preparación   → Desactivar módulos bloqueadores (scripts/paso-03-prep-modulos.sh)
4. Modelado      → Analizar componente y generar modelo (scripts/paso-04-modelado.sh)
5. Generación    → Crear backstop.json y scripts (scripts/paso-05-generacion.sh <site_alias> ...)
6. Ejecución     → Capturar referencia y ejecutar test (scripts/paso-06-ejecucion.sh <site_alias>)
7. Reporte       → Generar reporte y guía de re-ejecución (scripts/paso-07-reporte.sh <site_alias> ...)
```

## Scripts

| Script | Uso |
|--------|-----|
| `paso-01-analisis.sh` | Análisis de sitios y estructura del proyecto |
| `paso-02-setup.sh <site_alias>` | Instalar ddev-backstopjs add-on y crear estructura de directorios |
| `paso-03-prep-modulos.sh` | Desactivar módulos bloqueadores (cookies, captcha, shield) |
| `paso-04-modelado.sh` | Análisis del componente (menú, selector, página) |
| `paso-05-generacion.sh <site_alias> <model> <prod_url> <local_url>` | Generación de backstop.json y engine scripts |
| `paso-06-ejecucion.sh <site_alias> [mode]` | Ejecución de backstop reference + test |
| `paso-07-reporte.sh <site_alias> <type> <id>` | Generación de reporte final |

## Scaffolding de Infraestructura

Cuando la carpeta `tests/backstopjs/<site_alias>/` no existe, DEBES ejecutar `paso-02-setup.sh <site_alias>` para crearla. La estructura generada es:

```
tests/backstopjs/
  <site_alias>/                    ← Env folder (ej: uk, de, es)
    backstop.json                  ← Configuración principal de BackstopJS
    backstop_data/
      engine_scripts/
        puppet/
          onReady.js               ← Cookie dismissal + wait for fonts
          onBefore.js              ← Pre-navigation hooks
      bitmaps_reference/           ← Screenshots de PROD (referencia)
      bitmaps_test/                ← Screenshots locales (test)
      html_report/                 ← Reporte HTML de comparación
```

> **Nota**: El add-on monta `tests/backstopjs/` dentro del contenedor backstopjs como `/src/tests`. Los paths en `backstop.json` son **relativos al env folder** (ej: `backstop_data/bitmaps_reference`), NO rutas absolutas del host.

## Preparación del entorno

### Instalación del add-on ddev-backstopjs

BackstopJS se ejecuta en un **contenedor Docker dedicado** gestionado por el add-on DDEV. No es necesario instalar nada en el host ni en el contenedor web.

```bash
# DDEV >= 1.23.5 (pinned version for reproducibility)
ddev add-on get Metadrop/ddev-backstopjs@v2.8.0

# DDEV < 1.23.5
ddev get Metadrop/ddev-backstopjs@v2.8.0

# Reiniciar DDEV para activar el contenedor backstopjs (~1.6GB, primera vez tarda)
ddev restart
```

> **Actualización de versión**: Para actualizar el add-on, cambiar la versión en `paso-02-setup.sh` (variable `BACKSTOPJS_ADDON_VERSION`) y en esta documentación, luego ejecutar `ddev add-on get Metadrop/ddev-backstopjs@<nueva_version>` + `ddev restart`. Consultar el [changelog del add-on](https://github.com/Metadrop/ddev-backstopjs/releases) antes de actualizar.

`paso-02-setup.sh <site_alias>` automatiza este proceso y además crea la estructura de directorios y los scripts `onReady.js`/`onBefore.js` para el entorno indicado.

### Modos de ejecución

| Modo | Comando | Cuándo usarlo |
|------|---------|---------------|
| **Capturar referencia** | `ddev backstop <env> reference` | Primera vez o cuando PROD cambia intencionalmente |
| **Ejecutar test** | `ddev backstop <env> test` | Comparar local vs referencia |
| **Aprobar cambios** | `ddev backstop <env> approve` | Aceptar diferencias como nueva referencia |
| **Ver reporte** | `ddev backstopjs-report <env>` | Abrir reporte HTML en el navegador |

Donde `<env>` es el alias del sitio (ej: `uk`, `de`, `es`). Aliases del comando `ddev backstop`: `ddev backstopjs`, `ddev bkjs`.

## Problemas conocidos y soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `Environment 'uk' not found` | La carpeta `tests/backstopjs/uk/` o su `backstop.json` no existe | Ejecutar `paso-02-setup.sh uk` y `paso-05-generacion.sh uk ...` |
| Sitio sin URL DDEV configurada | `site_urls` en `progress.json` vacío para el alias | Añadir a `.ddev/config.yaml` `additional_hostnames: [alias]` + mapear en `sites.php` + `ddev restart` |
| Drush devuelve datos del sitio equivocado | `--uri` apunta a la URL incorrecta o no se pasa | Siempre usar `--uri=<SITE_URL>` completa (ej: `--uri=https://uk.ddev.site`), nunca solo el alias |
| Backstop captura el sitio equivocado | URL local incorrecta en `backstop.json` | Verificar `site_urls.<alias>` en `progress.json` y regenerar con la URL correcta |
| `Navigation timeout` | PROD URL inaccesible desde DDEV | Verificar DNS y acceso a internet desde contenedor |
| `net::ERR_CERT_AUTHORITY_INVALID` | SSL del sitio local | Ya incluido en config: `"engineOptions": { "args": ["--ignore-certificate-errors"] }` |
| Cookie banner en screenshots | Módulo de cookies activo | Ejecutar `paso-03-prep-modulos.sh <SITE_URL> --uninstall` + verificar `onReady.js` + añadir `hideSelectors` al escenario |
| Imágenes faltantes en LOCAL | Ficheros de PROD no sincronizados | Instalar `stage_file_proxy` con origin=PROD_URL o usar `removeSelectors` |
| Submenús no aparecen en screenshot | DOM manipulation insuficiente | Verificar `submenuTarget` + forzar `position: relative` en targets y wrappers |
| Header `position: fixed` — submenú cortado | Bounding box del header no crece | Usar `selectors: ["viewport"]` + `hideSelectors` para ocultar body (NO `removeSelectors` — ver regla crítica de submenús) |
| Diferencias por contenido dinámico | Carousels, fechas, ads | Añadir selectores dinámicos a `hideSelectors` o `removeSelectors` |
| `ddev restart` falla tras instalar add-on | Docker no puede descargar la imagen | Verificar conectividad Docker Hub / ghcr.io; la imagen pesa ~1.6GB |
| Contenedor backstopjs no arranca | Add-on instalado pero no reiniciado | Ejecutar `ddev restart` |

## Cómo guiar al usuario

Antes de cada fase, explica brevemente qué vas a hacer y por qué.
Después de cada paso, presenta un resumen conversacional.
Ante errores, da contexto y opciones claras.

## Dependencias opcionales

### extract-menu-links.php (script PHP auxiliar)

El script `paso-04-modelado.sh` (tipo `menu-pages`) intenta localizar un script PHP auxiliar en `scripts/extract-menu-links.php` en la **raíz del repositorio del proyecto** (4 niveles por encima del directorio `scripts/` del skill). Este archivo **no es parte del skill** y su presencia es opcional:

- Si existe, `drush scr` lo ejecuta para extraer los enlaces del menú (puede ser útil para proyectos con lógica de acceso compleja).
- Si no existe, el script cae automáticamente al fallback de `drush eval` inline, que funciona correctamente para la mayoría de casos.

No es necesario crear este archivo salvo que el fallback `drush eval` produzca resultados incompletos para el proyecto concreto.

## Reportes e Historial

- `reports/backstop-tests/progress.json` — Estado actual del proceso.
- `reports/backstop-tests/changelog.md` — Registro de cambios y mejoras.

## Referencia de Implementación

Consulta `README.md` para el plan de implementación detallado y mejores prácticas.
