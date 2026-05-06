# Ejemplo: Vista de Contenido del Usuario Actual

## Descripción

Vista que muestra el contenido creado por el usuario actualmente logueado. Útil para dashboards personales o secciones "Mi contenido".

**Caso de uso**: Bloque en el dashboard que lista los artículos del usuario con capacidad de editar/eliminar.

## Código Completo

### Paso 1: Crear Vista Base

```bash
ddev drush htoolkit:execute view_create '{
  "view_id": "my_content",
  "label": "My Content",
  "description": "Display content created by the current user",
  "base_table": "node_field_data",
  "display_title": "Default"
}'
```

### Paso 2: Añadir Display Block

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "my_content",
  "display_plugin": "block",
  "display_id": "block_1",
  "display_title": "My Content Block"
}'
```

### Paso 3: Configurar Style y Pager

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "display_options": {
    "style": {
      "type": "html_list"
    },
    "style_options": {
      "type": "ul",
      "class": "my-content-list"
    },
    "pager": {
      "type": "some",
      "options": {
        "items_per_page": 5,
        "offset": 0
      }
    }
  }
}'
```

### Paso 4: No se necesitan Relationships

Para este caso, no necesitamos relationships porque el campo `uid` está directamente en `node_field_data`.

### Paso 5: Añadir Campos

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "handler_type": "field",
  "handlers": {
    "title": {
      "id": "title",
      "table": "node_field_data",
      "field": "title",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "title",
      "plugin_id": "field",
      "label": "",
      "type": "string",
      "settings": {
        "link_to_entity": true
      }
    },
    "type": {
      "id": "type",
      "table": "node_field_data",
      "field": "type",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "type",
      "plugin_id": "field",
      "label": "",
      "type": "entity_reference_label",
      "settings": {
        "link": false
      }
    },
    "changed": {
      "id": "changed",
      "table": "node_field_data",
      "field": "changed",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "changed",
      "plugin_id": "field",
      "label": "",
      "type": "timestamp",
      "settings": {
        "date_format": "short",
        "custom_date_format": "",
        "timezone": ""
      }
    },
    "operations": {
      "id": "operations",
      "table": "node",
      "field": "operations",
      "relationship": "none",
      "entity_type": "node",
      "plugin_id": "entity_operations",
      "label": "",
      "destination": true
    }
  }
}'
```

### Paso 6: Añadir Filtros

**Clave**: El filtro `uid_current` filtra automáticamente por el usuario actual.

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "handler_type": "filter",
  "handlers": {
    "uid_current": {
      "id": "uid_current",
      "table": "node_field_data",
      "field": "uid_current",
      "relationship": "none",
      "entity_type": "node",
      "plugin_id": "user_current",
      "operator": "=",
      "value": "1",
      "group": 1,
      "exposed": false
    },
    "status": {
      "id": "status",
      "table": "node_field_data",
      "field": "status",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "status",
      "plugin_id": "boolean",
      "operator": "=",
      "value": "All",
      "group": 1,
      "exposed": true,
      "expose": {
        "operator_id": "status_op",
        "label": "Status",
        "identifier": "status",
        "required": false
      }
    },
    "type": {
      "id": "type",
      "table": "node_field_data",
      "field": "type",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "type",
      "plugin_id": "bundle",
      "operator": "in",
      "value": [],
      "group": 1,
      "exposed": true,
      "expose": {
        "operator_id": "type_op",
        "label": "Type",
        "identifier": "type",
        "required": false,
        "reduce": false
      }
    }
  }
}'
```

### Paso 7: Configurar Ordenamiento

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "handler_type": "sort",
  "handlers": {
    "changed": {
      "id": "changed",
      "table": "node_field_data",
      "field": "changed",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "changed",
      "plugin_id": "date",
      "order": "DESC"
    }
  }
}'
```

### Paso 8: No se necesitan Argumentos

Para este caso simple, no necesitamos argumentos contextuales.

## Resultado

Bloque disponible para colocar en cualquier región: "My Content Block"

### Características:
- **Lista HTML**: `<ul>` con clase CSS personalizada
- **5 items**: Muestra los 5 más recientes (sin paginador)
- **4 campos**: Title (enlazado), Type, Updated date, Operations
- **Filtro automático**: Solo contenido del usuario actual
- **2 filtros expuestos**: Status y Type
- **Ordenamiento**: Por fecha de modificación descendente

### Colocación del Bloque

Después de crear la vista, colocar el bloque:

```bash
# Opción 1: Desde la UI
Estructura > Diseño de bloques > Colocar bloque > My Content Block

# Opción 2: Programáticamente
ddev drush block:place my_content_block_1 --region=sidebar_first --weight=0
```

## Variaciones

### Opción 1: Display Page en lugar de Block

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "my_content",
  "display_plugin": "page",
  "display_id": "page_1",
  "display_title": "My Content Page",
  "display_options": {
    "path": "user/my-content"
  }
}'
```

Accesible en: `/user/my-content`

### Opción 2: Mostrar Drafts Separados

Añadir un segundo display para drafts:

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "my_content",
  "display_plugin": "block",
  "display_id": "block_2",
  "display_title": "My Drafts"
}'

# Luego sobrescribir el filtro de status
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "block_2",
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
      "exposed": false
    }
  }
}'
```

### Opción 3: Añadir Conteo Total

Añadir un header con el total:

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "handler_type": "header",
  "handlers": {
    "result": {
      "id": "result",
      "table": "views",
      "field": "result",
      "plugin_id": "result",
      "content": "You have @total content items."
    }
  }
}'
```

### Opción 4: Texto cuando está vacío

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "handler_type": "empty",
  "handlers": {
    "text": {
      "id": "text",
      "table": "views",
      "field": "area_text_custom",
      "plugin_id": "text_custom",
      "content": "<p>You haven'\''t created any content yet. <a href='\''/node/add'\''>Create content</a></p>",
      "tokenize": false
    }
  }
}'
```

## Access Control

Para restringir el acceso solo a usuarios autenticados:

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "display_options": {
    "access": {
      "type": "perm",
      "options": {
        "perm": "create article content"
      }
    }
  }
}'
```

O por rol:

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "display_options": {
    "access": {
      "type": "role",
      "options": {
        "role": {
          "authenticated": "authenticated"
        }
      }
    }
  }
}'
```

## Cache Configuration

Para mejor performance, configurar cache:

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "my_content",
  "display_id": "block_1",
  "display_options": {
    "cache": {
      "type": "tag",
      "options": {}
    }
  }
}'
```

## Notas Importantes

1. **uid_current**: Plugin especial que filtra automáticamente por el usuario actual
2. **Block placement**: Después de crear, colocar el bloque desde la UI o con Drush
3. **Performance**: Pager type "some" es más eficiente que "full" para bloques
4. **Operations**: Muestra Edit/Delete solo si el usuario tiene permisos
5. **Filtros expuestos en bloques**: Aparecen dentro del bloque mismo
6. **Cache**: Se invalida automáticamente cuando el usuario crea/edita/elimina contenido

## Testing

```bash
# Limpiar cache después de crear
ddev drush cr

# Verificar que el bloque está disponible
ddev drush block:list

# Ver el bloque
https://knowledge.ddev.site/admin/structure/block

# Probar como diferentes usuarios
# Crear contenido con user1, verificar que aparece
# Cambiar a user2, verificar que solo ve su contenido
```
