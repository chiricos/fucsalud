# Plan de Implementación Futura: Drupal BackstopJS

## 🚀 Próximos Componentes

### 1. Bloques (Views Blocks, Custom Blocks)
- **Objetivo**: Testear bloques individuales por su block ID o plugin ID.
- **Referencia**: `block--[id].tpl.php`, `#block-views-[view]-[display]`
- **Modelado**: Extraer lista de bloques visibles vía `drush views:list` o `block_content` entities.

### 2. Formularios (Webforms, Contact Forms)
- **Objetivo**: Capturar estado visual de formularios en diferentes estados (vacío, con errores, enviado).
- **Referencia**: `#webform-submission-[id]-add-form`
- **Integración**: Combinar con el skill `drupal-e2e-tests` para capturar screenshots durante tests funcionales.

### 3. Headers & Footers
- **Objetivo**: Testear header y footer de forma independiente con sus variaciones responsive.
- **Referencia**: `header`, `footer`, `.site-header`, `.site-footer`

### 4. Landing Pages completas
- **Objetivo**: Captura full-page de páginas de destino críticas.
- **Referencia**: Por ruta (`/`, `/products`, `/about`)

---

## 🔧 Mejoras Técnicas

### Ejecución Diferida de onReady
- Soporte para scripts `onReady` personalizados por escenario (no solo global).
- Útil para interactuar con tabs, acordeones o menús desplegables antes de capturar.

### Integración CI/CD
- Generar archivo de configuración para GitHub Actions / GitLab CI.
- Ejecutar `backstop test` en pipeline y fallar si hay regresiones.
- Subir HTML report como artifact.

### Multi-sitio en una ejecución
- Generar un `backstop.json` que combine escenarios de múltiples sitios (uk, de, es).
- Útil para validar un cambio de theme que afecta a todos los sitios.

### Comparación entre entornos
- No solo PROD vs LOCAL, sino también: PROD vs STAGING, STAGING vs LOCAL.
- Selección interactiva de entornos de origen y destino.

---

## 📊 Reportes Avanzados

### Dashboard de histórico
- Guardar resultados de cada ejecución con timestamp.
- Generar trending de diferencias a lo largo del tiempo.

### Slack/Teams Notifications
- Enviar resumen del test visual al canal del equipo tras cada ejecución en CI.
