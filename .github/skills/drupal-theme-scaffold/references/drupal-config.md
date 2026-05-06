# Archivos de configuración Drupal

Plantillas de los archivos de configuración del tema. Usadas por el **Subagente A**.

Aplica `{theme_name}` y `{web_root}` en todas las ocurrencias antes de crear los archivos.

---

### `{theme_name}.info.yml`

```yaml
name: {theme_name}
type: theme
base theme: false
description: "Tema personalizado {theme_name}"
package: Custom
version: VERSION
core_version_requirement: ^11

regions:
  header: Header
  tabs: Tabs
  content: Content
  footer: Footer
libraries:
  - '{theme_name}/global-styling'
```

---

### `{theme_name}.libraries.yml`

```yaml
global-styling:
  css:
    theme:
      assets/css/style.css: {}
      assets/css/layout/header.css: {}
      assets/css/layout/footer.css: {}
  js:
    js/custom/example.js: {}
  dependencies:
    - core/drupal
    - core/once
```

---

### `{theme_name}.theme`

```php
<?php
/**
 * @file
 * Theme functions.
 */

$includes_path = dirname(__FILE__) . '/includes/*.inc';
$routesMatched = glob($includes_path);
if (is_array($routesMatched)) {
  foreach ($routesMatched as $filename) {
    require_once dirname(__FILE__) . '/includes/' . basename($filename);
  }
}
```

---

### `includes/libraries.inc`

```php
<?php

/**
 * @file
 * Theme and libraries functions for items.
 */
```

---

### `includes/preprocess.inc`

```php
<?php

/**
 * @file
 * Theme and preprocess functions for items.
 */
```

---

### `includes/suggestions.inc`

```php
<?php

/**
 * @file
 * Theme and suggestions functions for items.
 */
```

---

### `js/custom/example.es6.js`

```js
(function (Drupal) {
  "use strict";

  Drupal.behaviors.{theme_name} = {
    attach(context) {

    },
  };
})(Drupal);
```

---

### `favicon.ico`

Crea un archivo `favicon.ico` vacío como placeholder.

---

### `logo.svg`

Copia el archivo `assets/logo.svg` (incluido en la skill) al directorio raíz del tema como `logo.svg`.

---

### Carpetas vacías (crear con `.gitkeep`)

- `assets/fonts/`
- `assets/images/`
- `assets/css/`
- `components/atoms/`
- `components/molecules/`
- `components/organisms/`
- `components/layouts/`
- `scss/components/`
- `scss/modules/`
- `scss/theme/`
