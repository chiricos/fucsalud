# Changelog - Drupal BackstopJS Visual Regression

## [2026-03-12] — Menu Pages Feature

### Added
- **`menu-pages` component type**: New option in the interactive flow that generates full-page BackstopJS scenarios for every link in a Drupal menu. The AI extracts all links from the specified menu (via `drush`), filters out external/invalid URLs, deduplicates, and creates one scenario per page across all three viewports.
- **Strategy section in SKILL.md**: Detailed instructions for the `menu-pages` flow including drush extraction command, filtering rules, scenario template, delay defaults, and stage_file_proxy requirements.
- **Differentiated backstop.json ID**: `menu-pages` tests use `[site]-menu-pages-[menu_name]` to avoid conflicts with `menu` component tests.

## [2026-03-09] — Initial Release

### Added
- **SKILL.md**: Full AI instructions for automated visual regression testing with BackstopJS.
- **README.md**: Implementation plan and documentation.
- **Multi-component support**: Skill supports menus (by machine name), selectors (CSS ID/class/attribute), and full pages (by path).
- **3 viewports**: Desktop (1920×1080), Tablet (768×1024), Mobile (375×812) configured by default.
- **7 scripts** for the complete workflow:
  - `paso-01-analisis.sh` — Project analysis, site detection, menu listing
  - `paso-02-setup.sh` — BackstopJS installation in DDEV, engine scripts creation
  - `paso-03-prep-modulos.sh` — Blocking module detection and removal (cookie banners, captcha, shield)
  - `paso-04-modelado.sh` — Component analysis (menu tree extraction, selector validation, page verification)
  - `paso-05-generacion.sh` — backstop.json generation with scenarios, viewports, and engine options
  - `paso-06-ejecucion.sh` — BackstopJS reference + test execution with modes (reference, test, approve, all)
  - `paso-07-reporte.sh` — Final report generation with re-execution commands
- **onReady.js**: Cookie banner dismissal for eu_cookie_compliance, CookieBot, and generic banners. Font loading wait. Lazy image scroll trigger.
- **onBefore.js**: Pre-navigation hook with Accept-Language header.
- **Troubleshooting guide**: Common issues and solutions (SSL, Chromium, timeouts, dynamic content).
- **Future plans**: Roadmap for blocks, forms, headers, CI/CD integration, multi-site execution.
- **Interactive flow**: AI asks user for site alias, component type, reference, and PROD URL before generating tests.
- **PROD as reference**: Production screenshots used as baseline, local DDEV as test target.
