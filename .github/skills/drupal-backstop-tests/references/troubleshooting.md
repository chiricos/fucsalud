# Resolución de Problemas (Troubleshooting) - Drupal BackstopJS

## 🌐 BackstopJS no puede acceder a la URL de PROD

### Problema
`backstop reference` falla con timeout o `net::ERR_NAME_NOT_RESOLVED` al intentar capturar screenshots de producción.

### Solución
1. Verificar que el contenedor DDEV tiene acceso a internet:
   ```bash
   ddev exec curl -s -o /dev/null -w "%{http_code}" https://www.google.com
   ```
2. Si devuelve `000`, hay un problema de DNS/red en Docker. Reiniciar Docker o DDEV.
3. Si la URL de PROD requiere VPN, asegurarse de que la VPN está activa en el host.

---

## 🔒 SSL Certificate Errors

### Problema
`net::ERR_CERT_AUTHORITY_INVALID` al capturar screenshots del sitio local DDEV.

### Solución
El `backstop.json` generado ya incluye `--ignore-certificate-errors` en `engineOptions.args`.
Si el error persiste:
```bash
ddev exec mkcert -install
```

---

## 🍪 Cookie Banners en Screenshots

### Problema
Las capturas muestran el banner de cookies superpuesto al contenido.

### Solución
1. Ejecutar `paso-03-prep-modulos.sh` con `--uninstall` para desactivar el módulo de cookies.
2. Verificar que `onReady.js` tiene los selectores correctos del banner. Ajustar si el sitio usa un módulo no estándar.
3. Añadir el banner a `removeSelectors` en `backstop.json`:
   ```json
   "removeSelectors": [".eu-cookie-compliance-banner", "#sliding-popup"]
   ```

---

## 🖼️ Chromium / Puppeteer no encontrado

### Problema
`Failed to launch the browser process` o `Chromium revision is not downloaded`.

### Solución
```bash
# Instalar Chromium dentro del contenedor DDEV
ddev exec npx puppeteer browsers install chrome

# Si falla, instalar dependencias de sistema
ddev exec sudo apt-get update -qq && ddev exec sudo apt-get install -y -qq chromium
```

---

## 📏 Screenshots tienen diferente tamaño

### Problema
BackstopJS reporta que las dimensiones no coinciden entre referencia y test.

### Solución
El `backstop.json` generado incluye `"requireSameDimensions": false`. Si quieres comparación estricta de dimensiones, cámbialo a `true`.

---

## ⏱️ Timeouts frecuentes

### Problema
Las capturas tardan demasiado y BackstopJS aborta.

### Solución
Aumentar `asyncCaptureLimit` a 2 (menos paralelo, menos recursos) y el `delay` del escenario:
```json
"asyncCaptureLimit": 2,
"scenarios": [{ "delay": 5000, ... }]
```

---

## 🔄 Diferencias por contenido dinámico

### Problema
Tests fallan constantemente por elementos que cambian: carousels, timestamps, ads.

### Solución
Añadir los selectores dinámicos a `hideSelectors` o `removeSelectors`:
```json
"hideSelectors": [".carousel", ".timestamp", ".ad-banner", ".social-feed"],
"removeSelectors": [".chat-widget"]
```
