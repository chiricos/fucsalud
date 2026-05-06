# Reglas de integración Figma → SCSS

Usada por el **Subagente B** cuando el usuario ha proporcionado URLs o IDs de Figma en el Paso 3.

---

## Colocación de tokens por tipo

| Tipo declarado | Dónde se aplican los tokens |
|---|---|
| `colors` | Reemplaza el bloque `// Colors` en `_variables-css.scss` (desde `--blue` hasta `--error`) |
| `typography` | Reemplaza o amplía las variables bajo `// Typography` en `_variables-css.scss`. Genera un archivo `fonts/_<nombre-fuente>.scss` por cada fuente detectada y actualiza `_fonts.scss` con los `@import` correspondientes |
| `spacing` | Reemplaza o amplía las variables bajo `// Layout` en `_variables-css.scss` |
| `other` | Añade un nuevo bloque al final de `:root { }` con comentario `// From <url>` y los tokens extraídos |

Si el usuario no indica el tipo de una URL, infiere el tipo por los nombres de los tokens del archivo Figma.

---

## Procesado multi-fuente

Cuando el usuario proporciona varias URLs:

1. Procesa cada URL de Figma de forma independiente según su tipo declarado.
2. Fusiona los resultados de todas las URLs en los archivos SCSS correspondientes.
3. Si dos fuentes generan variables con el mismo nombre, la última URL prevalece. Documenta el conflicto con un comentario junto a la variable afectada:
   ```scss
   // [CONFLICT resolved from <url>]
   --variable: value;
   ```

---

## Invariantes — nunca modificar

Los bloques `// Z-index` y `// Transition` en `_variables-css.scss` **siempre se mantienen tal cual**, independientemente de las URLs aportadas:

```scss
// Z-index
--z-index-2xs: 1;
--z-index-xs: 2;
--z-index-sm: 3;
--z-index-md: 4;
--z-index-lg: 5;
--z-index-xl: 5;
--z-index-menu: 100;
--z-index-modal: 200;
--z-index-error: 300;

// Transition
--base-trans: .25s ease-in-out;
--md-trans: .5s ease-in-out;
--lg-trans: 1s ease-in-out;
```
