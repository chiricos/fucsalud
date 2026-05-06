# Ejemplo: Vista con Filtro Contextual por Taxonomía

## Descripción

Vista que filtra contenido por término de taxonomía mediante URL, con soporte para múltiples valores.

**Caso de uso**: Mostrar todos los artículos etiquetados con uno o más tags específicos.

## Código Completo

### Paso 1: Crear Vista Base

```bash
ddev drush htoolkit:execute view_create '{
  "view_id": "taxonomy_view",
  "label": "Content by Tag",
  "description": "Display content filtered by taxonomy term",
  "base_table": "node_field_data",
  "display_title": "Default"
}'
```

### Paso 2: Añadir Display Page

```bash
ddev drush htoolkit:execute view_display_add '{
  "view_id": "taxonomy_view",
  "display_plugin": "page",
  "display_id": "page_1",
  "display_title": "Page",
  "display_options": {
    "path": "content/tag/%"
  }
}'
```

### Paso 3: Configurar Style y Pager

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "taxonomy_view",
  "display_id": "page_1",
  "display_options": {
    "style": {
      "type": "grid"
    },
    "style_options": {
      "columns": 3,
      "row_class": "",
      "default_row_class": true
    },
    "pager": {
      "type": "full",
      "options": {
        "items_per_page": 12,
        "offset": 0
      }
    }
  }
}'
```

### Paso 4: Añadir Relationship a Taxonomía

**Importante**: Este paso es necesario para poder filtrar por el campo de taxonomía.

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "taxonomy_view",
  "display_id": "page_1",
  "handler_type": "relationship",
  "handlers": {
    "field_tags": {
      "id": "field_tags",
      "table": "node__field_tags",
      "field": "field_tags",
      "relationship": "none",
      "admin_label": "Tags",
      "plugin_id": "standard",
      "required": false
    }
  }
}'
```

### Paso 5: Añadir Campos

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "taxonomy_view",
  "display_id": "page_1",
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
    "body": {
      "id": "body",
      "table": "node__body",
      "field": "body",
      "relationship": "none",
      "entity_type": "node",
      "plugin_id": "field",
      "label": "",
      "type": "text_summary_or_trimmed",
      "settings": {
        "trim_length": 200
      }
    },
    "field_tags": {
      "id": "field_tags",
      "table": "node__field_tags",
      "field": "field_tags",
      "relationship": "none",
      "entity_type": "node",
      "plugin_id": "field",
      "label": "Tags",
      "type": "entity_reference_label",
      "settings": {
        "link": true
      }
    }
  }
}'
```

### Paso 6: Añadir Filtro Base (Solo Publicados)

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "taxonomy_view",
  "display_id": "page_1",
  "handler_type": "filter",
  "handlers": {
    "status": {
      "id": "status",
      "table": "node_field_data",
      "field": "status",
      "entity_type": "node",
      "entity_field": "status",
      "plugin_id": "boolean",
      "operator": "=",
      "value": "1",
      "group": 1,
      "exposed": false
    },
    "type": {
      "id": "type",
      "table": "node_field_data",
      "field": "type",
      "entity_type": "node",
      "entity_field": "type",
      "plugin_id": "bundle",
      "operator": "in",
      "value": {
        "article": "article"
      },
      "group": 1,
      "exposed": false
    }
  }
}'
```

### Paso 7: Configurar Ordenamiento

```bash
ddev drush htoolkit:execute view_display_options_update '{
  "view_id": "taxonomy_view",
  "display_id": "page_1",
  "display_options": {
    "style_options": {
      "columns": 3,
      "row_class": "",
      "default_row_class": true
    }
  }
}'
```

### Paso 8: Añadir Argumento Contextual Multivaluado

**Clave**: `break_phrase: true` permite múltiples valores en la URL.

```bash
ddev drush htoolkit:execute view_handlers_update '{
  "view_id": "taxonomy_view",
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
      "not": false,
      "title": "Content tagged with %1",
      "default_argument_type": "fixed",
      "summary": {
        "number_of_records": 0,
        "format": "default_summary"
      }
    }
  }
}'
```

## Resultado

Vista accesible en: `/content/tag/[term_id]`

### Características:
- **Grid layout**: 3 columnas
- **Paginación**: 12 items por página
- **Filtro automático**: Solo artículos publicados
- **Argumento contextual**: Filtra por term ID(s) en la URL

### URLs de ejemplo:
- `/content/tag/1` → Contenido con tag ID 1
- `/content/tag/1+2+3` → Contenido con tags 1 O 2 O 3
- `/content/tag/all` → Sin filtro (muestra todos si se configura default_action)

## Variaciones

### Opción 1: Filtro AND (todos los tags)

Para requerir que el contenido tenga TODOS los tags (no solo uno):

```json
{
  "field_tags_target_id": {
    "break_phrase": true,
    "break_phrase_and": true
  }
}
```

URL: `/content/tag/1+2+3` → Contenido que tiene tag 1 Y 2 Y 3

### Opción 2: Excluir tags

Para mostrar contenido que NO tiene ciertos tags:

```json
{
  "field_tags_target_id": {
    "not": true
  }
}
```

URL: `/content/tag/1+2` → Contenido sin tags 1 ni 2

### Opción 3: Default action "not found"

Para mostrar 404 si no hay argumento:

```json
{
  "field_tags_target_id": {
    "default_action": "not found"
  }
}
```

Entonces `/content/tag/` → 404

### Opción 4: Usar nombre del término en lugar de ID

Requiere cambiar el plugin_id:

```json
{
  "field_tags_name": {
    "id": "field_tags_name",
    "table": "taxonomy_term_field_data",
    "field": "name",
    "relationship": "field_tags",
    "entity_type": "taxonomy_term",
    "plugin_id": "string",
    "default_action": "ignore",
    "break_phrase": true
  }
}
```

URL: `/content/tag/drupal` → Contenido con tag "drupal"

## Notas Importantes

1. **Relationship necesario**: El relationship a `node__field_tags` debe existir para que el argumento funcione correctamente
2. **break_phrase: true**: Esencial para múltiples valores con `+`
3. **Separador +**: En URLs, `+` significa OR, `,` también funciona
4. **default_action**: "ignore" muestra todos si no hay argumento, "not found" da 404
5. **Formato del título**: Usa `%1` para insertar el valor del argumento en el título de la página
6. **Performance**: En sitios grandes, considera añadir un índice en la tabla de taxonomía

## Testing

```bash
# Primero, obtener IDs de términos
ddev drush ev "print_r(\Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadByProperties(['vid' => 'tags']));"

# Luego visitar las URLs
https://knowledge.ddev.site/content/tag/1
https://knowledge.ddev.site/content/tag/1+2+3
```
