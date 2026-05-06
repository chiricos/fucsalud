---
name: drupal-twig-bridge
description: Use this skill when connecting a Drupal SDC component to a Drupal entity template. Trigger whenever the user mentions: node template, block template, paragraph template, taxonomy template, field template, entity twig, bridge component to entity, connect SDC to entity, field mapping, utility_classes, include vs embed Drupal, or creating/modifying any template that renders an SDC component with props. Use even if they only mention the entity type and a component name together.
allowed-tools:
  - read_file
  - file_search
  - grep_search
  - semantic_search
  - run_in_terminal
  - create_file
  - replace_string_in_file
  - runSubagent
---

## Rol

Especialista en conectar componentes SDC (modo `drupal-layout-builder`) con su template de entidad Twig correspondiente en Drupal. Actúa de puente entre el sistema de templates de Drupal y las props del componente SDC.

---

## Flujo de trabajo

### Paso 1 — Recoger datos

Hacer una única pregunta con todo lo necesario:

> "Indica:
> - **Tipo de entidad**: node / block / paragraph / taxonomy / field
> - **Bundle**: nombre del bundle (tipo de contenido, bundle de bloque, párrafo, vocabulario…)
> - **View mode**: `default`, `teaser`, `full`, `card`…
> - **Componente(s) SDC**: nombre del componente o componentes a renderizar. Si hay varios, indica qué campos va a cada uno. Ejemplo:
>   - `card-hero` → `field_image`, `title`, `field_subtitle`
>   - `rich-text` → `body`"

Si la entidad es un **bloque**, añadir a la pregunta:
> - **utility_classes**: ¿Este bloque usa utility_classes de vlsuite? Si es así, indica qué claves usa y a qué prop SDC mapea cada una.

---

### Paso 2 — Contexto automático (subagentes en paralelo)

Con los datos del paso 1, lanzar **todos los siguientes subagentes en la misma llamada** (son independientes entre sí):

**Subagente A — Referencia de entidad:**
- Leer el archivo `references/{entity}.md` de esta skill
- Retornar: variables disponibles, patrón de nombre de fichero, carpeta destino, y el array de clases
- Archivos: `references/node.md` / `references/block.md` / `references/paragraph.md` / `references/taxonomy.md` / `references/field.md`

**Subagente B — Display config:**
- Buscar en `config/sync/` (o `config/optional/`) el fichero:
  `core.entity_view_display.{entity_type}.{bundle}.{view_mode}.yml`
- Extraer la clave `content` del YAML: lista de campos visibles con su formatter
- Retornar los nombres de campo y el tipo de formatter de cada uno
- Si no existe, retornar vacío — el mapeo se acordará con el usuario manualmente

**Subagente C (uno por componente) — Props SDC:**
- Buscar `{component-name}.component.yml` dentro del directorio `components/` del tema
- Extraer todas las `props` y `slots` declarados
- Retornar: nombre de prop, tipo, si es requerida, y los slots disponibles

---

### Paso 3 — Propuesta de mapeo

Con los datos de los tres subagentes, cruzar los campos del display config con los nombres de las props SDC:
- Inferir el mapeo por nombre (`field_image` → prop `image`, `body` → prop `body`…)
- Para campos ambiguos o sin correspondencia obvia, presentar la duda al usuario
- Presentar al usuario un resumen del mapeo completo antes de generar

Consultar `references/field-access-patterns.md` para el patrón de acceso correcto según el tipo de campo:
- Imagen, vídeo, texto largo con formato → `content.field_name` (campo renderizado completo)
- Texto corto en bruto → `content.field_name.0['#context'].value`
- Enlace URL → `content.field_name.0['#url'].toString()`

---

### Paso 4 — Slots

Por cada componente, determinar si algún slot necesita sobreescribirse:
- Sin slots → `{% include %}`
- Con slots → `{% embed %}` con los `{% block %}` correspondientes

---

### Paso 5 — Generar

Generar el archivo de template en la carpeta y con el nombre de fichero correctos.
Nombre de fichero y carpeta destino están documentados en `references/{entity}.md`.
Para múltiples componentes, incluirlos en el orden indicado por el usuario.

---

## Reglas fundamentales

### include vs embed

| Usar | Cuándo |
|---|---|
| `{% include 'theme:component' with {...} only %}` | Sin slots |
| `{% embed 'theme:component' with {...} %}` | Uno o más `{% block %}` slots necesarios |

### Atributos y clases

Construir el array de clases **solo** si el componente SDC declara las props `*_classes` y `*_attributes`. Si no las declara, omitirlas por completo. Ver ejemplos completos en `references/{entity}.md`.

### utility_classes (bloques)

Las claves de `utility_classes` se mapean **siempre a una prop del componente** — nunca al array de clases. Siempre usar fallback `|default()`. Ver ejemplos en `references/block.md`.

---

## Checklist antes de generar

- [ ] `references/{entity}.md` leído → carpeta y patrón de nombre de fichero confirmados
- [ ] Display config leído → lista de campos activos disponible
- [ ] Props y slots de cada componente extraídos
- [ ] Mapeo campo → prop confirmado con el usuario
- [ ] Bloque: utility_classes mapeadas a props
- [ ] `*_classes` / `*_attributes` → pasarlas solo si el componente las declara
- [ ] ¿Slots? → `{% embed %}`; sin slots → `{% include %}`

---

## Referencias

- `references/node.md` — Variables, clases, ejemplos de template para nodos
- `references/block.md` — Variables, clases, utility_classes, ejemplos para bloques
- `references/paragraph.md` — Variables, clases, ejemplos para párrafos
- `references/taxonomy.md` — Variables, clases, ejemplos para términos de taxonomía
- `references/field.md` — Field templates: simple (pass-through) y complejo (array con merge)
- `references/field-access-patterns.md` — Tabla de patrones de acceso a campos por tipo

## Skills relacionadas

- **@sdc** — Para crear o editar el componente SDC antes de crear el template
- **@twig** — Estándares de seguridad y composición de templates Twig
- **@frontend** — SCSS architecture and preprocess hooks