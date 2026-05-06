# Troubleshooting — Errores Comunes en Actualizaciones Drupal

Referencia rápida para los agentes cuando encuentran errores durante el proceso.

---

## Errores de Composer

### "Your requirements could not be resolved to an installable set of packages"

**Causa:** Conflicto de dependencias.
**Acción:**
1. Identificar el paquete conflictivo en el mensaje de error
2. Ejecutar `ddev composer prohibits <paquete> <version>`
3. Reportar al usuario con la cadena de dependencias
4. NO intentar `--ignore-platform-reqs` sin aprobación

### "Package drupal/X has a PHP requirement incompatible with your PHP version"

**Causa:** La versión de PHP no cumple los requisitos.
**Acción:**
1. Leer la versión de PHP requerida del error
2. Proponer cambio: `ddev config --php-version=X.Y && ddev restart`
3. CONFIRMAR con usuario antes de ejecutar

### "cweagans/composer-patches: patch failed to apply"

**Causa:** El parche no aplica sobre la nueva versión del código.
**Acción:**
1. Identificar el parche que falla
2. Verificar si el issue fue resuelto en la nueva versión:
   - Revisar el URL del parche (generalmente drupal.org issue)
   - Buscar en las release notes si se incluyó el fix
3. Si fue resuelto → Recomendar eliminar el parche
4. Si NO fue resuelto → Recomendar actualizar el parche o crear uno nuevo
5. NUNCA eliminar parche sin aprobación

### "Allowed memory size exhausted"

**Causa:** Composer necesita más memoria.
**Acción:**
```bash
ddev exec COMPOSER_MEMORY_LIMIT=-1 composer update -W
```

### "Lock file is not up to date with the latest changes in composer.json"

**Causa:** Se modificó composer.json sin actualizar el lock.
**Acción:**
```bash
ddev composer update --lock
```

---

## Errores de Drush

### "Drupal\Core\Database\DatabaseExceptionWrapper"

**Causa:** Error de schema en la BD durante updatedb.
**Acción:**
1. Capturar el error completo
2. **ROLLBACK INMEDIATO** → `ddev snapshot restore <nombre>`
3. Investigar qué hook_update_N causó el error
4. Reportar al usuario

### "The following module is missing from the file system: X"

**Causa:** Módulo referenciado en BD pero no existe en el filesystem.
**Acción:**
```bash
# Verificar si el módulo está en composer.json
cat composer.json | jq '.require["drupal/X"]'

# Si no está, limpiarlo de la BD
ddev drush sql:query "DELETE FROM key_value WHERE collection='system.schema' AND name='X';"
```
**CONFIRMAR** con el usuario antes de ejecutar SQL directo.

### "Configuration X depends on the Y module"

**Causa:** Config huérfana que depende de un módulo desinstalado.
**Acción:**
1. Identificar la configuración problemática
2. Verificar si el módulo está habilitado: `ddev drush pm:list --status=enabled | grep X`
3. Si el módulo debe habilitarse: `ddev drush en X -y`
4. Si la config es huérfana: documentar para limpieza manual

---

## Errores de DDEV

### "Failed to start project: container exited"

**Causa:** Error en la configuración de DDEV o conflicto de puertos.
**Acción:**
```bash
ddev poweroff
ddev start
```

### "database server refused connection"

**Causa:** La BD no arrancó correctamente.
**Acción:**
```bash
ddev restart
ddev describe  # verificar estado
```

---

## Errores de Git

### "Your local changes would be overwritten"

**Causa:** Hay cambios sin commit que conflictúan.
**Acción:**
```bash
git stash
# ejecutar la operación
git stash pop  # recuperar cambios
```

---

## Errores Post-Update

### Pantalla blanca (WSOD)

**Acción inmediata:**
1. `ddev drush cr` (limpiar caché)
2. Si persiste: revisar `ddev logs`
3. Si persiste: **ROLLBACK** → `bash scripts/rollback.sh`

### Módulo incompatible causa error fatal

**Acción:**
```bash
# Desactivar el módulo problemático via settings.php
ddev exec sh -c 'echo "\$settings[\"container_yamls\"][] = \"sites/default/disable-module.yml\";" >> web/sites/default/settings.local.php'

# O más directo si Drush funciona:
ddev drush pm:uninstall <modulo_problematico> -y
ddev drush cr
```

### "The website encountered an unexpected error" en admin

**Acción:**
1. Revisar logs: `ddev drush watchdog:show --severity=error --count=20`
2. Si es error de schema: `ddev drush updatedb -y`
3. Si es módulo: identificar y deshabilitar
4. Si no se resuelve: **ROLLBACK**

---

## Regla de Oro del Troubleshooting

> Si después de 2 intentos de resolución el error persiste,
> EJECUTA ROLLBACK y reporta al usuario con todos los logs.
> Es mejor un rollback limpio que un sitio roto.
