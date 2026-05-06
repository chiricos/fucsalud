# Plantillas SCSS

Todas las plantillas de archivos SCSS del tema. Usadas por el **Subagente B**.

Aplica `{theme_name}` y `{web_root}` en todas las ocurrencias antes de crear los archivos.

> **Con datos Figma:** Si el usuario proporcionó URLs de Figma, lee `references/figma-scss-rules.md`. Las reglas de ese archivo tienen **prioridad sobre los valores por defecto** de esta plantilla — úsalos como base estructural pero sustituye los bloques indicados por los tokens extraídos de Figma.

---

## Tabla de contenidos

- [scss/_variables.scss](#scss_variablesscss)
- [scss/style.scss](#scssstylescss)
- [scss/base/_generic.scss](#scssbase_genericscss)
- [scss/layout/header.scss](#scsslayoutheaderscss)
- [scss/layout/footer.scss](#scsslayoutfooterscss)
- [scss/variables/_variables-css.scss](#scssvariables_variables-cssscss)
- [scss/variables/_mixins.scss](#scssvariables_mixinsscss)
- [scss/variables/_fonts.scss](#scssvariables_fontsscss)
- [scss/variables/fonts/_fuenteejemplo.scss](#scssvariablesfont_fuenteejemploscss)

---

### `scss/_variables.scss`

```scss
@import 'variables/fonts';
```

---

### `scss/style.scss`

```scss
// Variables
@import "variables";

// Base
@import "variables/variables-css";
@import "base/generic";
```

---

### `scss/base/_generic.scss`

```scss
/*
    - Name: "_generic.scss"
    - Description: "Add custom styles generic"
*/

* {
  font-display: swap;
}

*,
*::after,
*::before {
  box-sizing: border-box;
}

html {
  -webkit-overflow-scrolling: touch;
  box-sizing: border-box;
  width: 100%;
  color: var(--black);
  font-family: var(--regular);
  font-size: 100%;
  scroll-behavior: smooth;
}

body {
  margin: 0;
  background-color: var(--background-700);
  cursor: default;
  transition: var(--base-trans);

  &.scroll-off {
    overflow-y: hidden;
  }
}

main,
.block-system-main-block {
  color: var(--black);
  transition: var(--base-trans);
}

.visually-hidden, .visually-hidden-focusable:not(:focus, :focus-within) {
  position: absolute !important;
  overflow: hidden !important;
  clip: rect(0, 0, 0, 0) !important;
  width: 1px !important;
  height: 1px !important;
  margin: -1px !important;
  padding: 0 !important;
  border: 0 !important;
  white-space: nowrap !important;
}

img {
  max-width: 100%;
  height: auto;
}

[hidden] {
  display: none;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.container {
  max-width: 1980px;
  width: var(--container);
  margin: 0 auto;
  padding: 0 15px;
}
```

---

### `scss/layout/header.scss`

```scss
/*
    - Name: "header.scss"
    - Description: "Header custom styles"
*/

@use '../variables' as *;
```

---

### `scss/layout/footer.scss`

```scss
/*
    - Name: "footer.scss"
    - Description: "Add custom styles to Footer region"
*/

@use '../variables' as *;
```

---

### `scss/variables/_variables-css.scss`

La estructura base del archivo es la siguiente. El Subagente B debe respetar este orden de bloques y sustituir o ampliar cada sección con los tokens de Figma según su tipo. Los bloques `// Z-index` y `// Transition` **nunca se modifican**.

```scss
// Colors
:root {
  --blue: #19255A;
  --light-blue: #5B53FF;
  --blue-500: #ABB2CF;
  --aqua-500: #CDFAFF;
  --black: hsla(0, 0%, 0%, 1);
  --white: hsla(0, 0%, 100%, 1);
  --gray-900: #1D2024;
  --gray-500: #9e9e9e;
  --gray-200: #e9e9e9;
  --success: hsla(166, 51%, 33%, 1);
  --alert: hsla(40, 100%, 56%, 1);
  --error: hsla(355, 82%, 46%, 1);

  // Typography
  --regular: system-ui, sans-serif;

  // Layout
  --container: 90%;
  --background-700: #f5f5f5;

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
}
```

---

### `scss/variables/_mixins.scss`

```scss
/* Media query breakpoints */

$breakpoints: (
  xxs: 375px,
  xs: 480px,
  smx: 640px,
  sm: 768px,
  md: 992px,
  lg: 1024px,
  xl: 1200px,
  xxl: 1400px,
);

@mixin media-breakpoint-up($breakpoint) {
  @if map-has-key($breakpoints, $breakpoint) {
    $breakpoint-value: map-get($breakpoints, $breakpoint);
    @media (min-width: $breakpoint-value) {
      @content;
    }
  } @else {
    @warn 'Invalid breakpoint: #{$breakpoint}.';
  }
}

@mixin media-breakpoint-down($breakpoint) {
  @if map-has-key($breakpoints, $breakpoint) {
    $breakpoint-value: map-get($breakpoints, $breakpoint);
    @media (max-width: ($breakpoint-value - 1)) {
      @content;
    }
  } @else {
    @warn 'Invalid breakpoint: #{$breakpoint}.';
  }
}

@mixin font-face($name, $path, $weight: null, $style: null, $exts: eot woff2 woff ttf svg) {
  $src: null;

  $extmods: (
    eot: "?",
    svg: "#" + str-replace($name, " ", "_")
  );

  $formats: (
    otf: "opentype",
    ttf: "truetype"
  );

  @each $ext in $exts {
    $extmod: if(map-has-key($extmods, $ext), $ext + map-get($extmods, $ext), $ext);
    $format: if(map-has-key($formats, $ext), map-get($formats, $ext), $ext);
    $src: append($src, url(quote($path + "." + $extmod)) format(quote($format)), comma);
  }

  @font-face {
    font-family: quote($name);
    font-style: $style;
    font-weight: $weight;
    font-display: swap;
    src: $src;
  }
}

@mixin icomoon($size, $font: "icomoon") {
  font-family: $font;
  font-size: $size;
  speak: none;
  font-style: normal;
  font-weight: normal;
  font-variant: normal;
  font-display: swap;
  text-transform: none;
  line-height: 1;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

---

### `scss/variables/_fonts.scss`

```scss
@import 'mixins';

// @import 'fonts/example';

// @include font-face('icomoon', '/{web_root}/themes/custom/{theme_name}/assets/fonts/icomoon/icomoon', 400, normal, tff eot woff);
```

---

### `scss/variables/fonts/_fuenteejemplo.scss`

```scss
// @font-face {
//   font-display: swap;
//   font-family: "Poppins Semibold";
//   font-style: normal;
//   font-weight: 600;
//   src: url('/{web_root}/themes/custom/{theme_name}/assets/fonts/poppins/Poppins-SemiBold.woff2') format('woff2');
// }
```
