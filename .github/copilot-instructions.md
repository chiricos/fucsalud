# Copilot Instructions — Fucs Drupal Site

Drupal 9 site for Fundación Universidad de Ciencias de la Salud (FUCS), Colombia. Spanish-language content throughout.

## Local Development

```bash
ddev start               # Start environment
ddev drush uli           # Get one-time admin login link
ddev drush cr            # Clear all caches
ddev drush updb          # Run pending database updates
ddev drush cex           # Export config to sync/
ddev drush cim           # Import config from sync/
ddev composer <cmd>      # Run Composer commands inside DDEV
```

Stack: PHP 8.1, MariaDB 10.11, nginx-fpm (`.ddev/config.yaml`).

## Code Quality

```bash
# Static analysis (deprecation checks)
vendor/bin/drupal-check modules/custom/<module_name>

# Apply Drupal upgrade rules (Drupal 8/9/10 rule sets)
vendor/bin/rector process modules/custom/<module_name>

# Lint JS (extends Drupal core ESLint config)
npx eslint themes/custom/fucs/js/
```

## Architecture

### Custom Modules (`modules/custom/`)

| Module | Purpose |
|---|---|
| `fucs_form` | Admission/induction exam forms, PDF certificate generation (dompdf), email notifications |
| `certificados` | Certificate management |
| `online_shop_fucs` | E-commerce with Ecollet payment gateway, shopping cart, event subscribers |
| `drupal_google_auth` | Google OAuth integration |
| `fucs_modal` | Modal configuration |
| `fucs_studio_apartments` | Studio apartments listings |
| `invalid_nodes` | Node validation utilities |

### Custom Theme (`themes/custom/fucs/`)

Based on `classy`. Has 30+ named regions for fine-grained block placement (see `fucs.info.yml`). Template files follow Drupal Twig conventions with node-type-specific templates (`node--<content-type>.html.twig`). Partial includes split into `includes/` (header, footer, prehome, content).

The `fucs_form` module uses Tailwind CSS (`css/tailwind.css`) alongside custom CSS and jQuery.

### Configuration

Config sync directory: `sites/default/files/sync/`  
DDEV DB settings (auto-generated, do not edit): `sites/default/settings.ddev.php`

## Key Conventions

**Module structure** — all custom modules use the standard Drupal file pattern:
`.info.yml`, `.module`, `.routing.yml`, `.services.yml`, `.install`, `.libraries.yml`, `.permissions.yml`

**Namespacing** — PSR-4 under `Drupal\<module_name>\`. Typical subdirectories: `Controller/`, `Form/`, `Services/`, `Plugin/Block/`, `EventSubscriber/`

**Block IDs in code** — blocks are referenced by UUID plugin ID, e.g.:
```php
$block->getPluginId() == "block_content:d5e26f37-7602-41ae-b30f-4ae93b36e227"
```

**Theme hooks** — custom theme hooks are registered in `hook_theme()` inside `.module` files and map to Twig templates in `templates/`. Template naming convention: `block--<name>.html.twig`, `controller--<name>.html.twig`, `form--<name>.html.twig`.

**Services** — injected via `*.services.yml`; service classes live in `src/Services/`.

**Rector** — configured in `rector.php` with Drupal 8, 9, and 10 rule sets. Processes `.php`, `.module`, `.theme`, `.install`, `.profile`, `.inc`, `.engine` files.

**Language** — all user-facing strings, route titles, and admin labels are in Spanish.
