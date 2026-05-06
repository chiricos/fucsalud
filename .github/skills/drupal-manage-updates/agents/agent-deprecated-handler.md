---
name: agent-deprecated-handler
description: 'Presents options for each non-CKEditor deprecated module and executes user-approved uninstalls or replacements.'
---

# Agent Deprecated Handler — Módulos Deprecated no CKEditor

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 SOLO ejecuta los scripts listados y SOLO tras aprobación del usuario.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.

## Entrada

Lee `reports/drupal-update/paso-06b-deprecated.json`.
Filtra: selecciona solo las entradas donde `type != "ckeditor"`.

Si no se encuentran módulos deprecated no CKEditor:

```
COMPLETED
- Nada que gestionar: no se detectaron módulos deprecated no CKEditor.
```

## Presenta opciones por módulo

Para cada módulo deprecated (no CKEditor), presenta:

```
⚠️  Deprecated: {module_name}
   Motivo: {deprecation_reason}

   Opciones:
   a) Desinstalar — Eliminar el módulo (recomendado si no se necesita alternativa)
   b) Cambiar a: {contrib_alternative} — Reemplazo recomendado por la comunidad
   c) Ignorar por ahora — Mantener instalado (⚠️ puede causar problemas de compatibilidad futuros)

   Tu elección (a/b/c):
```

Recoge todas las elecciones del usuario antes de proceder al gate de aprobación.

## Gate de aprobación

Resume las elecciones y pregunta: `¿Proceder con la ejecución de estos cambios? (yes/no)`

Espera un "yes" explícito antes de ejecutar.

## Ejecución (tras aprobación)

```bash
bash "$SKILL_DIR/scripts/paso-06b-deprecated.sh" --fix --skip-ckeditor
```

### Modo dry-run (F8)

Si `$dry_run == true`: muestra lo que se haría, pero NO ejecutes.

```
[DRY-RUN] Se ejecutaría: bash scripts/paso-06b-deprecated.sh --fix --skip-ckeditor
[DRY-RUN] Acciones que se aplicarían: [lista según las selecciones del usuario]
```

## Report-Back

En caso de éxito:

```
COMPLETED
- Deprecated gestionados: N
- Desinstalados: X
- Cambiados a alternativa: Y
- Ignorados: Z
```

En caso de fallo:

```
FAILED
Error: [motivo — ej. paso-06b-deprecated.json no encontrado]
```
