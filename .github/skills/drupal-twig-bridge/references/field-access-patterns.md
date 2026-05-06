# Field Access Patterns

Cross-entity reference for reading Drupal field values inside Twig templates.

---

## Generic patterns (`content` variable)

| Dato necesario | Patrón |
|---|---|
| Campo renderizado completo | `content.field_name` |
| Primer ítem renderizado | `content.field_name.0` |
| Valor de texto en bruto | `content.field_name.0['#context'].value` |
| Título de enlace | `content.field_name.0['#title']` |
| URL de enlace | `content.field_name.0['#url'].toString()` |
| Target de enlace | `content.field_name.0['#url'].options['attributes'].target` |

---

## Campos de imagen, vídeo y texto largo con formato

Usar **siempre** el campo renderizado completo `content.field_name`. No acceder a subelementos — Drupal ya aplica el formatter correcto (responsive image, video embed, text processed…).

```twig
{% include "theme:component" with {
  image: content.field_image,
  video: content.field_video,
  body: content.body,
} only %}
```

> Esto aplica a tipos de campo `image`, `video_embed_field`, `text_with_summary`, `text_long`, y similares.

---

## Paragraph entity fields

| Dato necesario | Patrón |
|---|---|
| Valor de texto en bruto | `paragraph.field_name.value` |
| Campo de entidad referenciada | `paragraph.field_name.entity.field_name.value` |
| Target ID de referencia | `paragraph.field_name.target_id` |

---

## Taxonomy term fields

| Dato necesario | Patrón |
|---|---|
| Valor de texto en bruto | `term.field_name.value` |
| Entidad referenciada | `term.field_name.entity` |
| Nombre del término | `name` (variable disponible) o `term.name.value` |
| URL del término | `url` (variable disponible) |

---

## Inside `{% for item in items %}` (field templates)

| Dato necesario | Patrón |
|---|---|
| Entidad párrafo | `item.content['#paragraph']` |
| Texto en bruto del párrafo | `item.content['#paragraph'].field_name.value` |
| Campo de entidad referenciada del párrafo | `item.content['#paragraph'].field_name.entity.field_name.value` |
| Ítem renderizado | `item.content` |

Para construir un array de objetos planos desde ítems de campo, ver `references/field.md` — sección "Template — Complex".
