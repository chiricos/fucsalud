# Estructura de directorios del tema

Directorio raíz del tema: `{web_root}/themes/custom/{theme_name}/`

```
{web_root}/themes/custom/{theme_name}/
├── assets/
│   ├── fonts/          ← .gitkeep
│   ├── images/         ← .gitkeep
│   └── css/            ← .gitkeep (rellenado por gulp)
├── components/
│   ├── atoms/          ← .gitkeep
│   ├── molecules/      ← .gitkeep
│   ├── organisms/      ← .gitkeep
│   └── layouts/        ← .gitkeep
├── includes/
│   ├── libraries.inc
│   ├── preprocess.inc
│   └── suggestions.inc
├── js/
│   └── custom/
│       └── example.es6.js
├── scss/
│   ├── base/
│   │   └── _generic.scss
│   ├── components/     ← .gitkeep
│   ├── layout/
│   │   ├── header.scss
│   │   └── footer.scss
│   ├── modules/        ← .gitkeep
│   ├── theme/          ← .gitkeep
│   └── variables/
│       ├── fonts/
│       │   └── _fuenteejemplo.scss
│       ├── _fonts.scss
│       ├── _mixins.scss
│       └── _variables-css.scss
│   ├── style.scss
│   └── _variables.scss
├── templates/
│   ├── includes/
│   │   ├── header.html.twig
│   │   └── footer.html.twig
│   └── layout/
│       ├── page.html.twig
│       └── html.html.twig
├── {theme_name}.info.yml
├── {theme_name}.libraries.yml
├── {theme_name}.theme
├── favicon.ico
└── logo.svg
```

### Archivos en la raíz del proyecto

```
(project root)/
├── gulpfile.js         ← generado por Subagente D
└── package.json        ← generado por Subagente D
```
