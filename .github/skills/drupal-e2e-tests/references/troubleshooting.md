# Resolución de Problemas (Troubleshooting) - Drupal E2E Test Manager

Este documento detalla problemas comunes encontrados durante la configuración y ejecución de tests E2E y cómo solucionarlos.

---

## 🔐 Problemas de Certificados SSL / Red en Docker (WSL2)

### Problema
El contenedor de Playwright falla al construir (`ddev restart` o `ddev add-on get`) porque `apt-get update`, `curl` o `wget` no pueden verificar los certificados SSL de los repositorios. Esto suele ocurrir detrás de un proxy corporativo (ej: Zscaler, Hiberus, FortiGate).

### Solución recomendada: confiar en el certificado del proxy
El script `paso-02-setup.sh` detecta automáticamente proxies corporativos y añade su certificado CA al trust store del contenedor. Este es el método seguro.

Si necesitas hacerlo manualmente:
1. Extrae el certificado CA del proxy:
   ```bash
   echo | openssl s_client -connect packages.drupal.org:443 -showcerts 2>/dev/null \
     | awk '/-----BEGIN CERTIFICATE-----/{found++} found==2{print} /-----END CERTIFICATE-----/{if(found==2) exit}' \
     > /usr/local/share/ca-certificates/corporate-proxy.crt
   update-ca-certificates
   ```
2. Dentro del contenedor, los comandos `apt-get`, `curl` y `wget` funcionarán sin deshabilitar SSL.

> ⚠️ **No deshabilites la verificación SSL globalmente** (`Verify-Peer=false`, `-k`, `--no-check-certificate`). Esto expone el entorno a ataques MITM. Usa siempre el enfoque de trust store.

---

## 🛠️ Comando `jq` no encontrado en el Host

### Problema
Los scripts fallan al intentar procesar archivos JSON porque `jq` no está instalado en el sistema local (host).

### Solución
Los scripts de este skill han sido actualizados para:
1. Usar `ddev exec jq` para procesar archivos que están dentro del contenedor.
2. Usar `python3 -c "import json..."` para procesar JSON en el host, ya que Python suele estar disponible por defecto en entornos Linux/WSL2.

---

## 🏗️ Errores de Rebuild con DDEV v1.25+

### Problema
Tras actualizar a DDEV v1.25.x, el comando `ddev restart` intenta reconstruir las imágenes base. Debido a las restricciones SSL en la red local, la descarga de extensiones de PHP desde `packages.sury.org` falla con errores de certificados (`SSL connection failed`), impidiendo que el contenedor `web` arranque.

### Solución Recomendada
Si las imágenes base de tu versión actual de DDEV no están cacheadas y el rebuild falla por red, considera **usar una versión anterior de DDEV** cuyas imágenes ya tengas descargadas.

> **Nota**: La versión concreta puede variar. Consulta las [releases de DDEV](https://github.com/ddev/ddev/releases) para elegir una versión compatible con tu proyecto. En el momento de escribir esto, v1.24.x era una opción estable.

**Pasos para el downgrade (en el host):**
1. Consultar versiones disponibles en https://github.com/ddev/ddev/releases.
2. Descargar el binario (ej: `curl -LO https://github.com/ddev/ddev/releases/download/v1.24.7/ddev_linux_amd64.v1.24.7.tar.gz`).
3. Descomprimir y mover a `/usr/local/bin/ddev`.
4. Ejecutar `ddev poweroff`.
5. Ejecutar `ddev start`.

---

## 📋 El contenedor web falla con "phpstatus:FAILED"

### Problema
Al intentar listar los webforms, Drush devuelve un error indicando que el comando no está definido.

### Solución
1. Asegúrate de que el módulo `webform` está habilitado: `ddev drush pm:list | grep webform`.
2. En entornos multisitio, debes especificar la URI del sitio para que Drush cargue la configuración correcta:
   `ddev drush --uri=https://YOURSITE.ddev.site webform:list`
3. Si el comando sigue sin aparecer, intenta limpiar la caché de Drush: `ddev drush cr`.

---

## 🎭 El contenedor de Playwright no arranca

### Problema
`ddev describe` no muestra el servicio `playwright` o muestra un error de "Exit 1".

### Solución
1. Revisa los logs del contenedor: `docker logs ddev-YOURPROJECT-playwright`.
2. Asegúrate de que no hay conflictos de puertos (8444, 9323).
3. Intenta reconstruir el servicio: `ddev restart`.

---

## 🧪 Los tests fallan por "Timeout" esperando un selector

### Problema
Playwright no encuentra un campo del formulario y el test falla tras 30 segundos.

### Solución
1. **Verifica el selector**: Abre el sitio en el navegador, inspecciona el campo (F12) y asegúrate de que el ID o Name coincide con el usado en el test.
2. **Módulos Anti-spam**: Comprueba si `captcha` o `honeypot` están bloqueando el renderizado del formulario. Usa `paso-04-prep-modulos.sh`.
3. **Multisite**: Asegúrate de que el test está navegando a la URL correcta del sitio específico (ej: `/es/form/contact` vs `/form/contact`).
