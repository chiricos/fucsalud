# Ejemplo: Vista Administrativa Completa

## Descripción

Vista administrativa con:
- Tabla con bulk operations
- Paginación completa
- Filtros expuestos (title, tipo, status, fecha)
- Columnas ordenables
- Argumentos contextuales (tags y usuario)
- Operaciones CRUD en cada fila

## Código Completo

### Paso 1: Crear Vista Base

```bash
ddev drush htoolkit:execute view_create '{
  "view_id": "admin_content",
  "label": "Admin Content",
  "description": "Administrative content listing with advanced filtering and sorting",
  "base_table": "node_field_data",
  "display_title": "Default"
}'
```

### Paso 2: Añadir Display Page

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "admin_content",
  "display_plugin": "page",
  "display_id": "page_1",
  "display_title": "Page",
  "display_options": {
    "path": "admin/content-list"
  }
}'
```

### Paso 3: Configurar Style de Tabla y Pager

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "admin_content",
  "display_id": "page_1",
  "display_options": {
    "style": {
      "type": "table"
    },
    "pager": {
      "type": "full",
      "options": {
        "items_per_page": 50,
        "offset": 0
      }
    }
  }
}'
```

### Paso 4: Añadir Relationship al Autor

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "admin_content",
  "display_id": "page_1",
  "handler_type": "relationship",
  "handlers": {
    "uid": {
      "id": "uid",
      "table": "node_field_data",
      "field": "uid",
      "relationship": "none",
      "group_type": "group",
      "admin_label": "Author",
      "plugin_id": "standard",
      "required": false
    }
  }
}'
```

### Paso 5: Añadir Campos

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "admin_content",
  "display_id": "page_1",
  "handler_type": "field",
  "handlers": {
    "node_bulk_form": {
      "id": "node_bulk_form",
      "table": "node",
      "field": "node_bulk_form",
      "relationship": "none",
      "entity_type": "node",
      "plugin_id": "node_bulk_form",
      "label": ""
    },
    "title": {
      "id": "title",
      "table": "node_field_data",
      "field": "title",
      "relationship": "none",
      "entity_type": "node",
      "entity_field": "title",
      "plugin_id": "field",
      "label": "Title",
      "type": "string",
      "settings": {
        "link_to_entity": true
      }
    },
    "type": {
      "id": "type",
      "table": "node_field_data",
      "field": "type",
      "entity_type": "node",
      "entity_field": "type",
      "plugin_id": "field",
      "label": "Content type",
      "type": "entity_reference_label",
      "settings": {
        "link": false
      }
    },
    "status": {
      "id": "status",
      "table": "node_field_data",
      "field": "status",
      "entity_type": "node",
      "entity_field": "status",
      "plugin_id": "field",
      "label": "Published",
      "type": "boolean"
    },
    "changed": {
      "id": "changed",
      "table": "node_field_data",
      "field": "changed",
      "entity_type": "node",
      "entity_field": "changed",
      "plugin_id": "field",
      "label": "Updated",
      "type": "timestamp",
      "settings": {
        "date_format": "short"
      }
    },
    "operations": {
      "id": "operations",
      "table": "node",
      "field": "operations",
      "entity_type": "node",
      "plugin_id": "entity_operations",
      "label": "Operations",
      "destination": true
    }
  }
}'
```

### Paso 6: Configurar Columnas Ordenables

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "admin_content",
  "display_id": "page_1",
  "display_options": {
    "style_options": {
      "info": {
        "node_bulk_form": {
          "align": "",
          "separator": "",
          "empty_column": false,
          "responsive": ""
        },
        "title": {
          "sortable": true,
          "default_sort_order": "asc",
          "align": "",
          "separator": "",
          "empty_column": false,
          "responsive": ""
        },
        "type": {
          "sortable": true,
          "default_sort_order": "asc",
          "align": "",
          "separator": "",
          "empty_column": false,
          "responsive": ""
        },
        "status": {
          "sortable": false,
          "default_sort_order": "asc",
          "align": "",
          "separator": "",
          "empty_column": false,
          "responsive": ""
        },
        "changed": {
          "sortable": true,
          "default_sort_order": "desc",
          "align": "",
          "separator": "",
          "empty_column": false,
          "responsive": ""
        },
        "operations": {
          "align": "",
          "separator": "",
          "empty_column": false,
          "responsive": ""
        }
      },
      "default": "changed",
      "order": "desc",
      "override": true,
      "sticky": false,
      "summary": "",
      "empty_table": false,
      "caption": ""
    }
  }
}'
```

### Paso 7: Añadir Filtros Expuestos

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "admin_content",
  "display_id": "page_1",
  "handler_type": "filter",
  "handlers": {
    "title": {
      "id": "title",
      "table": "node_field_data",
      "field": "title",
      "entity_type": "node",
      "entity_field": "title",
      "plugin_id": "string",
      "operator": "contains",
      "value": "",
      "group": 1,
      "exposed": true,
      "expose": {
        "operator_id": "title_op",
        "label": "Title",
        "description": "",
        "use_operator": false,
        "operator": "title_op",
        "identifier": "title",
        "required": false,
        "remember": false,
        "multiple": false,
        "placeholder": ""
      }
    },
    "type": {
      "id": "type",
      "table": "node_field_data",
      "field": "type",
      "entity_type": "node",
      "entity_field": "type",
      "plugin_id": "bundle",
      "operator": "in",
      "value": [],
      "group": 1,
      "exposed": true,
      "expose": {
        "operator_id": "type_op",
        "label": "Content type",
        "identifier": "type",
        "required": false,
        "reduce": false
      }
    },
    "status": {
      "id": "status",
      "table": "node_field_data",
      "field": "status",
      "entity_type": "node",
      "entity_field": "status",
      "plugin_id": "boolean",
      "operator": "=",
      "value": "All",
      "group": 1,
      "exposed": true,
      "expose": {
        "label": "Published",
        "identifier": "status"
      }
    },
    "changed": {
      "id": "changed",
      "table": "node_field_data",
      "field": "changed",
      "entity_type": "node",
      "entity_field": "changed",
      "plugin_id": "date",
      "operator": ">=",
      "value": {
        "min": "",
        "max": "",
        "value": "",
        "type": "offset"
      },
      "group": 1,
      "exposed": true,
      "expose": {
        "operator_id": "changed_op",
        "label": "Changed",
        "identifier": "changed"
      }
    }
  }
}'
```

### Paso 8: Añadir Argumentos Contextuales

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "admin_content",
  "display_id": "page_1",
  "handler_type": "argument",
  "handlers": {
    "field_tags_target_id": {
      "id": "field_tags_target_id",
      "table": "node__field_tags",
      "field": "field_tags_target_id",
      "entity_type": "node",
      "entity_field": "field_tags",
      "plugin_id": "numeric",
      "default_action": "ignore",
      "break_phrase": true,
      "not": false
    },
    "name": {
      "id": "name",
      "table": "users_field_data",
      "field": "name",
      "relationship": "uid",
      "entity_type": "user",
      "entity_field": "name",
      "plugin_id": "string",
      "default_action": "ignore",
      "break_phrase": false
    }
  }
}'
```

## Resultado

Vista accesible en: `/admin/content-list`

### Características:
- **Bulk operations**: Checkbox para operaciones masivas
- **6 columnas**: Bulk form, Title, Content type, Published, Updated, Operations
- **Ordenamiento**: Title, Type y Changed son ordenables, ordenado por Changed DESC por defecto
- **Paginación**: 50 items por página con paginador completo
- **4 filtros expuestos**: Title (texto), Type (select), Status (boolean), Changed (fecha)
- **2 argumentos contextuales**: Tags (multivaluado) y Username

### URLs de ejemplo:
- `/admin/content-list` → Todos los nodos
- `/admin/content-list?title=test&type=article` → Con filtros
- `/admin/content-list/1+2+3` → Nodos con tags 1, 2 o 3
- `/admin/content-list/1+2+3/admin` → Nodos con tags y del usuario admin

## Notas

- Los bulk operations requieren el módulo `node` habilitado
- El filtro por fecha usa formato "offset" para fechas relativas
- El relationship "uid" permite filtrar por nombre de usuario en los argumentos
- Las operations muestran enlaces Edit, Delete, etc. según permisos
