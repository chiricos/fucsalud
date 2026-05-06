# Build Tooling

Archivos del sistema de build con Gulp. Usadas por el **Subagente D**.

Se crean en la **raíz del proyecto**, al mismo nivel que `composer.json`, `.ddev/` y `vendor/`. Sustituye `{web_root}` en el `basePath` del `gulpfile.js` con el valor detectado en el Paso 2.

---

## Contenido

- [package.json](#packagejson-raíz-del-proyecto)
- [gulpfile.js](#gulpfilejs-raíz-del-proyecto)

---

### `package.json` (raíz del proyecto)

```json
{
  "name": "{theme_name}",
  "version": "1.0.0",
  "description": "{theme_name} theme implementation",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "lint": "stylelint \"**/*.scss\""
  },
  "keywords": [
    "SASS",
    "Drupal"
  ],
  "author": "@hatuhay",
  "license": "MIT",
  "devDependencies": {
    "@babel/core": "^7.22.11",
    "@babel/preset-env": "^7.18.9",
    "autoprefixer": "^10.4.14",
    "chalk": "^4.1.0",
    "chromatic": "^11.5.4",
    "del": "^6.0.0",
    "gulp": "^4.0.2",
    "gulp-babel": "^8.0.0",
    "gulp-cached": "^1.1.1",
    "gulp-clean-css": "4.3.0",
    "gulp-concat": "^2.6.1",
    "gulp-debug": "^4.0.0",
    "gulp-dependents": "^1.2.5",
    "gulp-html-replace": "^1.6.2",
    "gulp-load-plugins": "^2.0.4",
    "gulp-postcss": "^9.0.1",
    "gulp-rename": "^1.2.2",
    "gulp-replace-name": "^1.0.1",
    "gulp-sass": "^5.0.0",
    "gulp-sourcemaps": "^3.0.0",
    "html-react-parser": "^1.4.14",
    "merge-stream": "^2.0.0",
    "postcss": "^8.4.21",
    "postcss-pxtorem": "^5.1.1",
    "prettier": "^3.0.3"
  },
  "dependencies": {
    "babel-loader": "^8.3.0",
    "gulp-cli": "^3.0.0",
    "sass": "~1.64.2"
  }
}
```

---

### `gulpfile.js` (raíz del proyecto)

```js
// phpcs:disable Generic.PHP.UpperCaseConstant.Found
// phpcs:disable Squiz.WhiteSpace.OperatorSpacing.NoSpaceAfter
// phpcs:disable Squiz.WhiteSpace.OperatorSpacing.NoSpaceBefore

const gulp = require("gulp"),
  sass = require("gulp-sass")(require("sass")),
  sourcemaps = require("gulp-sourcemaps"),
  $ = require("gulp-load-plugins")(),
  postcss = require("gulp-postcss"),
  cached = require("gulp-cached"),
  chalk = require("chalk"),
  dependents = require("gulp-dependents"),
  debug = require("gulp-debug"),
  autoprefixer = require("autoprefixer"),
  replaceName = require("gulp-replace-name"),
  babel = require("gulp-babel"),
  pxtorem = require("postcss-pxtorem"),
  merge = require("merge-stream"),
  fs = require("fs"),
  path = require("path");

// Ruta base de temas y microsites
const basePath = "./{web_root}/themes/custom/";

// Detectar dinámicamente todos los temas y microsites dentro de /custom
const themes = fs
  .readdirSync(basePath)
  .filter((file) => fs.statSync(path.join(basePath, file)).isDirectory());

console.log(chalk.cyan("Temas detectados:"), themes);

// PostCSS processors
const postcssProcessors = [
  pxtorem({
    propList: ["font", "font-size", "line-height", "letter-spacing"],
    mediaQuery: false,
  }),
  autoprefixer(),
];

/**
 * Compile SCSS to CSS with sourcemaps and PostCSS processors
 */
function compileScss(src, dest) {
  return gulp
    .src(src, { allowEmpty: true })
    .pipe(sourcemaps.init())
    .pipe(cached("sass"))
    .pipe(dependents())
    .pipe(debug({ title: "Compiling SCSS:" }))
    .pipe(sass().on("error", sass.logError))
    .pipe(postcss(postcssProcessors))
    .pipe(sourcemaps.write("."))
    .pipe(gulp.dest(dest));
}

/**
 * Compile ES6 files to standard JavaScript using Babel
 */
function compileJs(src, dest) {
  return gulp
    .src(src, { allowEmpty: true })
    .pipe(babel({ presets: ["@babel/preset-env"], sourceType: "script" }))
    .pipe(replaceName(/\.es6/g, ""))
    .pipe(gulp.dest(dest));
}

/**
 * Crear tareas dinámicas de estilos para todos los temas y microsites
 */
function styles() {
  console.log(
    chalk.inverse.greenBright(" DONE "),
    chalk.inverse.green(" Compiling SCSS for all themes/microsites "),
  );
  let tasks = themes.map((theme) => {
    let themePath = path.join(basePath, theme);
    return merge(
      compileScss(`${themePath}/scss/**/*.scss`, `${themePath}/assets/css/`),
      compileScss(
        `${themePath}/components/**/*.scss`,
        `${themePath}/components/`,
      ),
    );
  });
  return merge(...tasks);
}

/**
 * Crear tareas dinámicas de JS para todos los temas y microsites
 */
function es6() {
  let tasks = themes.map((theme) => {
    let themePath = path.join(basePath, theme);
    return merge(
      compileJs(`${themePath}/js/**/*.es6.js`, `${themePath}/js/`),
      compileJs(
        `${themePath}/components/**/*.es6.js`,
        `${themePath}/components/`,
      ),
    );
  });
  return merge(...tasks);
}

/**
 * Watch for file changes in all themes/microsites
 */
function watchFiles() {
  themes.forEach((theme) => {
    let themePath = path.join(basePath, theme);
    gulp.watch(
      [`${themePath}/scss/**/*.scss`, `${themePath}/components/**/*.scss`],
      styles,
    );
    gulp.watch(
      [`${themePath}/js/**/*.es6.js`, `${themePath}/components/**/*.es6.js`],
      es6,
    );
  });
}

// Define Gulp tasks
exports.default = gulp.parallel(styles, es6);
exports.watch = gulp.series(styles, es6, watchFiles);
exports.compile = styles;
exports.js = es6;
```
