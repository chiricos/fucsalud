# Changelog - Drupal E2E Test Manager

## [2026-03-06] — Media Library Support & Scaffolding

### Added
- **Rule 17**: `media_library` field type support. Fields that open a jQuery UI modal dialog
  are now fully testable. The overlay (`ui-widget-overlay`) intercepts Playwright pointer events,
  so all interaction inside the modal uses `page.evaluate()` with jQuery triggers.
- **Rule 18**: Scaffolding for new projects. Before generating any `.spec.ts`, the skill now
  verifies that the test infrastructure exists (`playwright.config.ts`, `form.helper.ts`, fixture
  and helper directories). If missing, it creates everything before generating the first test.
- **Phase 5b**: New "Scaffolding" step between Modelado and Generación in the process flow.
- **`selectMediaLibraryItem()` helper**: Reusable function in `form.helper.ts` that handles the
  full media library modal flow: open → wait → select item via jQuery → insert → wait for close.
- **Canonical helper table**: `form.helper.ts` now documents all required functions and their
  corresponding Drupal field types.
- **3 new entries** in the known problems/solutions table for media library-specific errors:
  - `ui-widget-overlay intercepts pointer events`
  - `Clicking the checkbox did not change its state`
  - `"Insert selected" button hidden`
- **Scaffolding directory structure** documented in a new "Scaffolding de Infraestructura" section.

### Fixed
- Tests no longer skip `media_library` fields — they are handled like any other field type.
- Prevented scenario where a `.spec.ts` imports helpers that don't exist yet on a fresh project.

## [2026-03-05]
### Added
- Estructura base del skill `drupal-e2e-tests`.
- `SKILL.md` con las fases iniciales y regla técnica para `--reporter=line`.
- `README.md` con el plan de implementación detallado.
- Repositorio de reportes inicializado.
- **Requirement**: Se ha añadido la obligatoriedad de verificar y desinstalar módulos bloqueadores (captcha, honeypot, etc.) en `SKILL.md`.
- **paso-04-prep-modulos.sh**: Actualizado para aceptar `site_uri` y flag `--uninstall` para automatizar la limpieza del entorno.
- **Requirement**: Añadida instrucción en `SKILL.md` para buscar accesos públicos (nodos/modales) si el webform no es accesible vía admin.
- **paso-05-modelado.sh**: Mejorado con un parser de Python para extraer metadatos de validación (`#required`, `#pattern`, `#type`) de cada elemento del webform.
- **Requirement**: Añadida regla técnica #8 en `SKILL.md` para obligar a generar datos de prueba que cumplan con las validaciones detectadas.
- **Requirement**: Añadida regla técnica #10 en `SKILL.md` para obligar a testear **todas las ramas de lógica condicional** (campos ocultos/visibles).
- **paso-05-modelado.sh**: Actualizado con lógica para detectar y extraer el bloque `#states` de Drupal, permitiendo mapear dependencias entre campos.
- **paso-08-reporte.sh**: Nuevo script para generar un resumen ejecutivo del test creado, con comandos de ejecución y rutas de archivos.
- **Requirement**: Añadida regla técnica #10 en `SKILL.md` para obligar a mostrar el reporte final al usuario con los modos de ejecución (headless, headed, UI).
- **Documentation**: Creado `references/future-plans.md` con la hoja de ruta para tests complejos, autenticación, Cypress y CI/CD.

### Fixed (IA)
- **paso-02-setup.sh**: Implementada creación de `.ddev/web-build/Dockerfile` y `.ddev/db-build/Dockerfile` con configuraciones para omitir verificación SSL de APT, `curl` y `wget`.
- **paso-02-setup.sh**: Añadida lógica para forzar el uso de HTTP en lugar de HTTPS en los repositorios de `/etc/apt/sources.list.d/` (como el de sury.org) para evitar fallos de certificados durante el rebuild de DDEV v1.25.
- **paso-02-setup.sh**: Implementado parche automático para el `Dockerfile` del addon `ddev-playwright`.
- **paso-02-setup.sh**: Añadido flag `--strict-ssl false` a los comandos `npm install` para evitar fallos de certificados durante la instalación de paquetes.
- **paso-04-prep-modulos.sh**: Eliminada dependencia de `jq` en el host, sustituyéndola por `python3` para procesar el JSON de `drush pm:list` y la configuración de `flood`.
- **paso-05-modelado.sh**: Mejorado el análisis básico de YAML para extraer `title`, `confirmation_message` y nombres de `elements` usando `grep/sed` y `python3`.
- General: Estandarizado el uso de `python3` para manipulación de JSON en el host para evitar errores de entorno.
