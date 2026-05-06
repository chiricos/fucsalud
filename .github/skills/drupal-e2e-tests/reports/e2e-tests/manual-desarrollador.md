# Manual del Desarrollador: Tests E2E con Playwright

Este documento explica cómo ejecutar y mantener los tests E2E generados para el proyecto.

## 🚀 Ejecución de Tests

Los tests se ejecutan dentro del contenedor de Playwright gestionado por DDEV.

### 1. Ejecución Estándar (Headless)
Ejecuta todos los tests en segundo plano y muestra los resultados en la consola:
```bash
ddev exec npx playwright test --reporter=line
```

### 2. Ejecutar un Test Específico
```bash
ddev exec npx playwright test tests/playwright/tests/<your-test>.spec.ts --reporter=line
```

### 3. Modo Interactivo (UI Mode)
Para depurar visualmente los tests:
```bash
ddev playwright test --ui
```
*Nota: Requiere que el puerto 9323 esté accesible.*

## 🛠️ Configuración y Mantenimiento

### Cambio de Sitio (Multisite)
Para probar diferentes sitios, edita la `baseURL` en `playwright.config.ts`.
Ejemplo: `https://<site-alias>.ddev.site`

### Módulos que interfieren
Los módulos anti-spam como **Captcha** o **Honeypot** bloquean los tests automatizados.

> ⚠️ `pm:uninstall` elimina la configuración del módulo en BD. Tras los tests, reinstala y reimporta config.

- **Desinstalar temporalmente:** `ddev drush --uri=[SITE_URL] pm:uninstall captcha honeypot -y`
- **Reinstalar:** `ddev drush --uri=[SITE_URL] pm:install captcha honeypot -y && ddev drush --uri=[SITE_URL] config:import -y`

## 📁 Estructura de Archivos
- `tests/playwright/tests/`: Contiene los archivos `.spec.ts` (escenarios de prueba).
- `tests/playwright/tests/helpers/`: Clases de utilidad para formularios.
- `tests/playwright/fixtures/`: Datos de prueba aleatorios.

## 🔐 Notas de Seguridad (WSL2/Entornos Restringidos)
Si el contenedor falla al reconstruir por errores SSL (ej: proxy corporativo), el script `paso-02-setup.sh` detecta automáticamente certificados de proxy y los añade al trust store del contenedor. Si la detección automática no funciona, puedes añadir manualmente el certificado CA de tu proxy a `/usr/local/share/ca-certificates/` dentro del contenedor y ejecutar `update-ca-certificates`.

**No deshabilites la verificación SSL globalmente** (`Acquire::https::Verify-Peer "false"`, `insecure` en curlrc, etc.) ya que esto expone el entorno a ataques MITM durante la instalación de dependencias.
