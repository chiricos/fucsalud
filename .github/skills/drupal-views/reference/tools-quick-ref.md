# Referencia Rápida: Plugins htoolkit_views para Views

Todos los plugins se invocan con:
```bash
ddev drush htoolkit:execute <tool_id> '<JSON>'
```

Para ver la definición completa de un plugin (parámetros, tipos, descripción):
```bash
ddev drush htoolkit:info <tool_id>
```

Para listar todos los plugins de views disponibles:
```bash
ddev drush htoolkit:list --module=htoolkit_views
```

---

## view_create

**Propósito**: Crear nueva vista con configuración básica

**Parámetros**:
```json
{
  "view_id": "string",       // REQUERIDO: ID máquina (snake_case)
  "label": "string",         // REQUERIDO: Etiqueta legible
  "description": "string",   // REQUERIDO: Descripción
  "base_table": "string",    // REQUERIDO: node_field_data, users_field_data, etc.
  "display_title": "string"  // OPCIONAL: Título del display default
}
```

**Retorna**:
```json
{
  "view_id": "mi_vista",
  "view_label": "Mi Vista",
  "message": "View created successfully."
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_create '{"view_id":"mi_vista","label":"Mi Vista","description":"Descripción","base_table":"node_field_data"}'
```

---

## view_display_add

**Propósito**: Añadir nuevo display a una vista

**Parámetros**:
```json
{
  "view_id": "string",          // REQUERIDO: ID de la vista
  "display_plugin": "string",   // REQUERIDO: page, block, feed, attachment, embed, entity_reference
  "display_id": "string",       // REQUERIDO: ID del display (ej: page_1)
  "display_title": "string",    // REQUERIDO: Título del display
  "display_options": {          // OPCIONAL: Opciones adicionales
    "path": "string"            // Para page: ruta de la página
  }
}
```

**Retorna**:
```json
{
  "view_id": "mi_vista",
  "display_id": "page_1",
  "display_config": "...",
  "message": "Display added successfully."
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_display_add '{"view_id":"mi_vista","display_plugin":"page","display_id":"page_1","display_title":"Page","display_options":{"path":"mi-ruta"}}'
```

---

## view_display_plugins_list

**Propósito**: Listar todos los plugins de display disponibles

**Parámetros**: Ninguno (pasar `{}`)

**Retorna**:
```json
{
  "plugins": {
    "page": {
      "id": "page",
      "label": "Page",
      "description": "Display the view as a page..."
    },
    "block": {}
  }
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_display_plugins_list '{}'
```

---

## view_display_options_list

**Propósito**: Listar opciones configurables para un tipo de opción de display

**Parámetros**:
```json
{
  "view_id": "string",              // REQUERIDO: ID de la vista
  "display_id": "string",           // REQUERIDO: ID del display
  "display_option_type": "string"   // REQUERIDO: tipo de opción
}
```

**Tipos de opciones válidos**:
- `style` / `style_options`
- `row` / `row_options`
- `pager` / `pager_options`
- `exposed_form` / `exposed_form_options`
- `access` / `access_options`
- `path`, `menu`, `cache`, `css_class`
- `use_ajax`, `hide_attachment_summary`, `show_admin_links`, `group_by`, `query`

**Retorna**:
```json
{
  "options": {
    "options.style.type": {
      "key": "type",
      "type": "radios",
      "title": "Style",
      "options": {
        "table": "Table",
        "grid": "Grid"
      }
    }
  }
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_display_options_list '{"view_id":"mi_vista","display_id":"page_1","display_option_type":"style"}'
```

---

## view_display_options_update

**Propósito**: Actualizar opciones de display (style, pager, exposed_form, etc.) — devuelve YAML

**Parámetros**:
```json
{
  "view_id": "string",        // REQUERIDO: ID de la vista
  "display_id": "string",     // REQUERIDO: ID del display
  "display_options": {}       // REQUERIDO: Mapa de opciones a actualizar
}
```

**Ejemplo de display_options**:
```json
{
  "style": {
    "type": "table"
  },
  "pager": {
    "type": "full",
    "options": {
      "items_per_page": 10,
      "offset": 0
    }
  },
  "style_options": {
    "info": {
      "title": {
        "sortable": true,
        "default_sort_order": "asc"
      },
      "changed": {
        "sortable": true,
        "default_sort_order": "desc"
      }
    },
    "default": "changed",
    "order": "desc"
  },
  "access": {
    "type": "perm",
    "options": {
      "perm": "administer nodes"
    }
  }
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_display_options_update '{"view_id":"mi_vista","display_id":"page_1","display_options":{"style":{"type":"table"},"pager":{"type":"full","options":{"items_per_page":10}}}}'
```

---

## view_handler_fields_list

**Propósito**: Listar campos disponibles para un handler type

**Parámetros**:
```json
{
  "view_id": "string",       // REQUERIDO: ID de la vista
  "display_id": "string",    // REQUERIDO: ID del display
  "handler_type": "string"   // REQUERIDO: field, filter, argument, sort, relationship, header, footer, empty
}
```

**Retorna**:
```json
{
  "fields": {
    "node_field_data.title": {
      "id": "node_field_data.title",
      "title": "Title",
      "group": "Content",
      "table": "node_field_data",
      "field": "title",
      "plugin_id": "field"
    },
    "node_field_data.type": {}
  },
  "handler_info": {
    "title": "Fields",
    "ltitle": "fields"
  }
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_handler_fields_list '{"view_id":"mi_vista","display_id":"page_1","handler_type":"field"}'
```

---

## view_handler_field_options

**Propósito**: Obtener opciones de configuración para un campo específico

**Parámetros**:
```json
{
  "view_id": "string",       // REQUERIDO: ID de la vista
  "display_id": "string",    // REQUERIDO: ID del display
  "handler_type": "string",  // REQUERIDO: field, filter, argument, sort, relationship
  "field_id": "string"       // REQUERIDO: ID en formato "tabla.campo"
}
```

**Retorna**:
```json
{
  "field_info": {
    "id": "node_field_data.title",
    "title": "Title",
    "plugin_id": "field"
  },
  "configurable_options": {
    "label": {
      "type": "textfield",
      "title": "Label",
      "default_value": "Title"
    },
    "settings": {
      "link_to_entity": {
        "type": "checkbox",
        "title": "Link to entity"
      }
    }
  }
}
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_handler_field_options '{"view_id":"mi_vista","display_id":"page_1","handler_type":"field","field_id":"node_field_data.title"}'
```

---

## view_handlers_update

**Propósito**: Actualizar handlers (fields, filters, arguments, sorts, relationships) — devuelve YAML

**Parámetros**:
```json
{
  "view_id": "string",       // REQUERIDO: ID de la vista
  "display_id": "string",    // REQUERIDO: ID del display
  "handler_type": "string",  // REQUERIDO: field, filter, argument, sort, relationship, header, footer, empty
  "handlers": {}             // REQUERIDO: Mapa de configuraciones, keyed por ID único
}
```

**Estructura de handlers para handler_type "field"**:
```json
{
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
    "plugin_id": "field",
    "label": "Content type",
    "type": "entity_reference_label",
    "settings": {
      "link": false
    }
  }
}
```

**Estructura de handlers para handler_type "filter"**:
```json
{
  "title": {
    "id": "title",
    "table": "node_field_data",
    "field": "title",
    "entity_type": "node",
    "plugin_id": "string",
    "operator": "contains",
    "value": "",
    "group": 1,
    "exposed": true,
    "expose": {
      "operator_id": "title_op",
      "label": "Title",
      "identifier": "title",
      "required": false,
      "remember": false
    }
  },
  "status": {
    "id": "status",
    "table": "node_field_data",
    "field": "status",
    "entity_type": "node",
    "plugin_id": "boolean",
    "operator": "=",
    "value": "All",
    "group": 1,
    "exposed": true,
    "expose": {
      "label": "Published",
      "identifier": "status"
    }
  }
}
```

**Estructura de handlers para handler_type "argument"**:
```json
{
  "field_tags_target_id": {
    "id": "field_tags_target_id",
    "table": "node__field_tags",
    "field": "field_tags_target_id",
    "entity_type": "node",
    "plugin_id": "numeric",
    "default_action": "ignore",
    "break_phrase": true,
    "not": false
  }
}
```

**Estructura de handlers para handler_type "relationship"**:
```json
{
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
```

**Ejemplo**:
```bash
ddev drush htoolkit:execute view_handlers_update '{"view_id":"mi_vista","display_id":"page_1","handler_type":"field","handlers":{"title":{"id":"title","table":"node_field_data","field":"title","plugin_id":"field","label":"Title"}}}'
```

---

## Patrones de Uso Común

### 1. Crear Vista Completa

```bash
# Paso 1: Crear
ddev drush htoolkit:execute view_create '{"view_id":"mi_vista","label":"Mi Vista","description":"Descripción","base_table":"node_field_data"}'

# Paso 2: Añadir display
ddev drush htoolkit:execute view_display_add '{"view_id":"mi_vista","display_plugin":"page","display_id":"page_1","display_title":"Page","display_options":{"path":"mi-ruta"}}'

# Paso 3: Configurar style y pager
ddev drush htoolkit:execute view_display_options_update '{"view_id":"mi_vista","display_id":"page_1","display_options":{"style":{"type":"table"},"pager":{"type":"full","options":{"items_per_page":10}}}}'

# Paso 4: Añadir campos
ddev drush htoolkit:execute view_handlers_update '{"view_id":"mi_vista","display_id":"page_1","handler_type":"field","handlers":{"title":{},"type":{}}}'

# Paso 5: Añadir filtros
ddev drush htoolkit:execute view_handlers_update '{"view_id":"mi_vista","display_id":"page_1","handler_type":"filter","handlers":{"title":{"exposed":true}}}'

# Paso 6: Configurar ordenamiento
ddev drush htoolkit:execute view_display_options_update '{"view_id":"mi_vista","display_id":"page_1","display_options":{"style_options":{"info":{"title":{"sortable":true}},"default":"changed","order":"desc"}}}'
```

### 2. Consultar Antes de Configurar

```bash
# Siempre primero: listar campos disponibles
ddev drush htoolkit:execute view_handler_fields_list '{"view_id":"mi_vista","display_id":"page_1","handler_type":"field"}'

# Luego: obtener opciones del campo específico
ddev drush htoolkit:execute view_handler_field_options '{"view_id":"mi_vista","display_id":"page_1","handler_type":"field","field_id":"node_field_data.title"}'

# Finalmente: configurar
ddev drush htoolkit:execute view_handlers_update '{...}'
```

### 3. Herencia de Display Default

```bash
# Configurar en default (se hereda a todos)
ddev drush htoolkit:execute view_handlers_update '{"view_id":"mi_vista","display_id":"default","handler_type":"filter","handlers":{"status":{"value":"1"}}}'

# Sobrescribir en display específico
ddev drush htoolkit:execute view_handlers_update '{"view_id":"mi_vista","display_id":"page_1","handler_type":"filter","handlers":{"status":{"value":"All"}}}'
```

---

## Campos Plugin_ID Comunes

### Para Fields
- `field` → Campo genérico
- `entity_operations` → Enlaces CRUD
- `node_bulk_form` → Operaciones bulk

### Para Filters
- `string` → Filtro de texto
- `boolean` → Filtro booleano
- `numeric` → Filtro numérico
- `date` → Filtro de fecha
- `bundle` → Filtro por tipo de contenido
- `taxonomy_index_tid` → Filtro por taxonomía
- `user_current` → Filtro por usuario actual

### Para Arguments
- `numeric` → Argumento numérico
- `string` → Argumento de texto
- `date` → Argumento de fecha

### Para Relationships
- `standard` → Relationship estándar
