# Ejemplo: Vista con Control de Acceso

## Descripción

Ejemplos de cómo configurar diferentes tipos de control de acceso en vistas: por permisos, por roles, y por usuarios específicos.

## Control de Acceso por Permiso

### Código

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "restricted_view",
  "display_id": "page_1",
  "display_options": {
    "access": {
      "type": "perm",
      "options": {
        "perm": "administer nodes"
      }
    }
  }
}'
```

### Permisos Comunes

- `administer nodes` - Administrar contenido
- `administer users` - Administrar usuarios
- `administer site configuration` - Administrar configuración del sitio
- `access administration pages` - Acceder a páginas administrativas
- `view own unpublished content` - Ver propio contenido no publicado
- `edit any article content` - Editar cualquier artículo
- `delete any article content` - Eliminar cualquier artículo

## Control de Acceso por Rol

### Código

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "restricted_view",
  "display_id": "page_1",
  "display_options": {
    "access": {
      "type": "role",
      "options": {
        "role": {
          "administrator": "administrator",
          "editor": "editor"
        }
      }
    }
  }
}'
```

### Roles del Sistema

- `anonymous` - Usuario anónimo
- `authenticated` - Usuario autenticado
- `administrator` - Administrador
- Custom roles: usar el machine name del rol

## Control de Acceso Ninguno (Público)

### Código

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "public_view",
  "display_id": "page_1",
  "display_options": {
    "access": {
      "type": "none",
      "options": {}
    }
  }
}'
```

## Ejemplo Completo: Vista Administrativa Restringida

Vista que solo pueden ver administradores y editores, mostrando contenido sin publicar.

### Paso 1-3: Crear Vista, Display y Style (estándar)

```bash
ddev drush htoolkit:execute view_create '{
  "view_id": "unpublished_content",
  "label": "Unpublished Content",
  "description": "Content awaiting review",
  "base_table": "node_field_data"
}'

ddev drush htoolkit:execute view_display_add '{
  "view_id": "unpublished_content",
  "display_plugin": "page",
  "display_id": "page_1",
  "display_title": "Page",
  "display_options": {
    "path": "admin/unpublished-content"
  }
}'

ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "unpublished_content",
  "display_id": "page_1",
  "display_options": {
    "style": {"type": "table"},
    "pager": {"type": "full", "options": {"items_per_page": 25}}
  }
}'
```

### Paso 4: Configurar Access Control por Rol

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "unpublished_content",
  "display_id": "page_1",
  "display_options": {
    "access": {
      "type": "role",
      "options": {
        "role": {
          "administrator": "administrator",
          "editor": "editor"
        }
      }
    }
  }
}'
```

### Paso 5: Añadir Campos

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "unpublished_content",
  "display_id": "page_1",
  "handler_type": "field",
  "handlers": {
    "title": {
      "id": "title",
      "table": "node_field_data",
      "field": "title",
      "entity_type": "node",
      "plugin_id": "field",
      "label": "Title",
      "type": "string",
      "settings": {"link_to_entity": true}
    },
    "type": {
      "id": "type",
      "table": "node_field_data",
      "field": "type",
      "entity_type": "node",
      "plugin_id": "field",
      "label": "Type"
    },
    "uid": {
      "id": "uid",
      "table": "node_field_data",
      "field": "uid",
      "entity_type": "node",
      "plugin_id": "field",
      "label": "Author",
      "type": "entity_reference_label",
      "settings": {"link": true}
    },
    "created": {
      "id": "created",
      "table": "node_field_data",
      "field": "created",
      "entity_type": "node",
      "plugin_id": "field",
      "label": "Created",
      "type": "timestamp",
      "settings": {"date_format": "short"}
    },
    "operations": {
      "id": "operations",
      "table": "node",
      "field": "operations",
      "entity_type": "node",
      "plugin_id": "entity_operations",
      "label": "Operations"
    }
  }
}'
```

### Paso 6: Filtro para Solo No Publicados

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "unpublished_content",
  "display_id": "page_1",
  "handler_type": "filter",
  "handlers": {
    "status": {
      "id": "status",
      "table": "node_field_data",
      "field": "status",
      "entity_type": "node",
      "plugin_id": "boolean",
      "operator": "=",
      "value": "0",
      "group": 1,
      "exposed": false
    }
  }
}'
```

### Paso 7: Ordenar por Fecha de Creación

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "unpublished_content",
  "display_id": "page_1",
  "display_options": {
    "style_options": {
      "info": {
        "title": {"sortable": true},
        "created": {"sortable": true, "default_sort_order": "desc"}
      },
      "default": "created",
      "order": "desc"
    }
  }
}'
```

## Ejemplo: Vista con Acceso por Permiso Custom

Para usar un permiso personalizado de tu módulo.

### Definir el Permiso (en tu módulo)

```yaml
# my_module.permissions.yml
view custom reports:
  title: 'View custom reports'
  description: 'Access to view custom analytics reports'
```

### Configurar la Vista

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "custom_reports",
  "display_id": "page_1",
  "display_options": {
    "access": {
      "type": "perm",
      "options": {
        "perm": "view custom reports"
      }
    }
  }
}'
```

## Ejemplo: Diferentes Accesos por Display

Una misma vista puede tener diferentes controles de acceso por display.

### Display 1: Solo Administradores

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "multi_access_view",
  "display_plugin": "page",
  "display_id": "admin_page",
  "display_title": "Admin Page",
  "display_options": {"path": "admin/full-data"}
}'

ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "multi_access_view",
  "display_id": "admin_page",
  "display_options": {
    "access": {
      "type": "role",
      "options": {
        "role": {"administrator": "administrator"}
      }
    }
  }
}'
```

### Display 2: Usuarios Autenticados

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "multi_access_view",
  "display_plugin": "page",
  "display_id": "user_page",
  "display_title": "User Page",
  "display_options": {"path": "user/limited-data"}
}'

ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "multi_access_view",
  "display_id": "user_page",
  "display_options": {
    "access": {
      "type": "role",
      "options": {
        "role": {"authenticated": "authenticated"}
      }
    }
  }
}'
```

### Display 3: Público

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "multi_access_view",
  "display_plugin": "page",
  "display_id": "public_page",
  "display_title": "Public Page",
  "display_options": {"path": "public-data"}
}'

ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "multi_access_view",
  "display_id": "public_page",
  "display_options": {
    "access": {
      "type": "none",
      "options": {}
    }
  }
}'
```

## Control de Acceso a Nivel de Campos

Además del acceso a la vista completa, puedes controlar qué campos se muestran según permisos usando el sistema de Field Access de Drupal. Esto se configura a nivel de campo, no en la vista.

### Ejemplo: Campo Sensible

Si tienes un campo que solo ciertos usuarios deben ver (ej: `field_salary`), configura su acceso en el módulo que define el campo:

```php
// my_module.module
function my_module_entity_field_access($operation, FieldDefinitionInterface $field_definition, AccountInterface $account, FieldItemListInterface $items = NULL) {
  if ($field_definition->getName() == 'field_salary' && $operation == 'view') {
    return AccessResult::allowedIfHasPermission($account, 'view salary information');
  }
  return AccessResult::neutral();
}
```

## Combinación con Filtros Contextuales

Para vistas donde usuarios ven solo su propio contenido:

```bash
# Access: Cualquier usuario autenticado
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "my_content",
  "display_id": "page_1",
  "display_options": {
    "access": {
      "type": "role",
      "options": {
        "role": {"authenticated": "authenticated"}
      }
    }
  }
}'

# Pero filtro por usuario actual
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "page_1",
  "handler_type": "filter",
  "handlers": {
    "uid_current": {
      "id": "uid_current",
      "table": "node_field_data",
      "field": "uid_current",
      "plugin_id": "user_current",
      "value": "1"
    }
  }
}'
```

## Notas Importantes

1. **Verificar roles**: Los machine names de los roles son case-sensitive
2. **Permisos existentes**: Verifica que el permiso existe antes de usarlo
3. **Access vs Filtros**: Access controla quién ve la vista, filtros controlan qué contenido ven
4. **Cache**: Los permisos afectan el cache, Drupal maneja esto automáticamente
5. **Testing**: Siempre probar con diferentes usuarios/roles
6. **Hierarchy**: Si un usuario tiene múltiples roles, se evalúan todos
7. **Override**: Cada display puede tener su propio access control

## Testing

```bash
# Ver roles disponibles
ddev drush role:list

# Ver permisos de un rol
ddev drush role:perm:list editor

# Añadir permiso a rol
ddev drush role:perm:add editor "view custom reports"

# Remover permiso
ddev drush role:perm:remove editor "view custom reports"

# Probar como usuario específico
# 1. Crear usuario de prueba
ddev drush user:create testuser --mail="test@example.com" --password="test"

# 2. Asignar rol
ddev drush user:role:add editor testuser

# 3. Probar acceso
# Logearse como testuser y visitar la vista
```
