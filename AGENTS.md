# AGENTS.md - Fucs Drupal Site

## Project Type
Drupal 9 site for Fucs (Fundación Universidad de Ciencias de la Salud, Colombia)

## Local Development

```bash
ddev start          # Start environment
ddev drush uli      # Get one-time admin login link
ddev drush cr       # Clear cache
ddev drush updb     # Run database updates
ddev composer       # Run composer commands
```

DDEV config: `.ddev/config.yaml` (PHP 8.1, MariaDB 10.11, nginx-fpm)

## Drush Commands

```bash
drush updb          # Run pending updates
drush cr            # Clear all caches
drush cex           # Export config to sync/
drush cim           # Import config
drush sql:dump > backup.sql  # Database dump
```

## Custom Modules
Located in `/modules/custom/`:
- `fucs_form` - Main forms module (uses dompdf for PDF generation)
- `fucs_modal`, `fucs_studio_apartments`, `certificados`, `drupal_google_auth`, `invalid_nodes`, `online_shop_fucs`

## Custom Theme
- `/themes/custom/fucs/` - Based on classy, extensive region definitions

## Code Quality

```bash
vendor/bin/drupal-check modules/custom/fucs_form  # Static analysis
vendor/bin/rector process modules/custom/fucs_form  # Apply upgrade rules
```

Rector configured with Drupal 8/9/10 sets in `rector.php`

## Configuration
- Config sync: `sites/default/files/sync/` (export with `drush cex`)
- DDEV settings: `sites/default/settings.ddev.php`

## Important Notes
- This is a Spanish-language site (Colombia)
- Custom modules use `.module`, `.install`, `.routing.yml`, `.services.yml` patterns
- Block IDs referenced by UUID in code (e.g., `block_content:d5e26f37-7602-41ae-b30f-4ae93b36e227`)
