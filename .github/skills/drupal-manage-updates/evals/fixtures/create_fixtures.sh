#!/usr/bin/env bash
# =============================================================================
# create_fixtures.sh -- Genera (o regenera) los fixtures mock para los evals
#
# Uso: bash evals/fixtures/create_fixtures.sh
# Idempotente: usa mkdir -p y sobrescribe ficheros existentes.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Creating fixtures in: $SCRIPT_DIR"

# =============================================================================
# Fixture 1: d10-minor-update
# Drupal 10.2.5, 3 patches, bridge + target + manual modules, PHP 8.2
# =============================================================================
mkdir -p "$SCRIPT_DIR/d10-minor-update/.ddev"

cat > "$SCRIPT_DIR/d10-minor-update/composer.json" << 'JSONEOF'
{
  "name": "drupal/recommended-project",
  "description": "Fixture: Drupal 10.2.5 minor update scenario",
  "type": "project",
  "license": "GPL-2.0-or-later",
  "require": {
    "composer/installers": "^2.2",
    "drupal/address": "^2.0",
    "drupal/admin_toolbar": "^3.4",
    "drupal/ckeditor5": "^1.0",
    "drupal/core-composer-scaffold": "10.2.5",
    "drupal/core-recommended": "10.2.5",
    "drupal/ctools": "^4.0",
    "drupal/devel": "^5.0",
    "drupal/field_group": "^3.4",
    "drupal/metatag": "^2.0",
    "drupal/paragraphs": "^1.15",
    "drupal/pathauto": "^1.11",
    "drupal/redirect": "^1.8",
    "drupal/token": "^1.12",
    "drupal/views_bulk_operations": "^4.2",
    "drupal/webform": "^6.1",
    "drupal/xmlsitemap": "^1.4",
    "drupal/search_api": "^1.29",
    "drupal/facets": "^2.0",
    "drupal/entity_reference_revisions": "^1.10",
    "drupal/layout_builder_restrictions": "^2.14",
    "drupal/block_visibility_groups": "^2.0",
    "drupal/crop": "^2.3",
    "drupal/focal_point": "^2.0",
    "drupal/media_entity_browser": "^2.0"
  },
  "extra": {
    "drupal-scaffold": {"locations": {"web-root": "web/"}},
    "installer-paths": {
      "web/core": ["type:drupal-core"],
      "web/modules/contrib/{$name}": ["type:drupal-module"],
      "web/themes/contrib/{$name}": ["type:drupal-theme"]
    },
    "patches": {
      "drupal/core": {"Fix node access query issue": "patches/node-access-fix.patch"},
      "drupal/metatag": {"SEO canonical URL fix": "patches/metatag-seo.patch"},
      "drupal/token": {"Token cache invalidation fix": "patches/token-cache.patch"}
    }
  },
  "config": {
    "allow-plugins": {
      "composer/installers": true,
      "drupal/core-composer-scaffold": true
    }
  }
}
JSONEOF

cat > "$SCRIPT_DIR/d10-minor-update/.ddev/config.yaml" << 'YAMLEOF'
name: drupal-fixture-d10-minor
type: drupal
docroot: web
php_version: "8.2"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
YAMLEOF

echo "  [OK] d10-minor-update"

# =============================================================================
# Fixture 2: d10-to-d11-jump
# Drupal 10.6.3, PHP 8.3, 2 modules without D11 versions
# =============================================================================
mkdir -p "$SCRIPT_DIR/d10-to-d11-jump/.ddev"

cat > "$SCRIPT_DIR/d10-to-d11-jump/composer.json" << 'JSONEOF'
{
  "name": "drupal/recommended-project",
  "description": "Fixture: Drupal 10.6.3 major jump to D11 scenario",
  "type": "project",
  "license": "GPL-2.0-or-later",
  "require": {
    "composer/installers": "^2.2",
    "drupal/address": "^2.0",
    "drupal/admin_toolbar": "^3.4",
    "drupal/core-composer-scaffold": "10.6.3",
    "drupal/core-recommended": "10.6.3",
    "drupal/ctools": "^4.0",
    "drupal/devel": "^5.0",
    "drupal/field_group": "^3.4",
    "drupal/gin": "^3.0",
    "drupal/gin_toolbar": "^1.0",
    "drupal/metatag": "^2.0",
    "drupal/paragraphs": "^1.17",
    "drupal/pathauto": "^1.12",
    "drupal/redirect": "^1.9",
    "drupal/search_api": "^1.31",
    "drupal/facets": "^2.0",
    "drupal/token": "^1.13",
    "drupal/views_bulk_operations": "^4.3",
    "drupal/webform": "^6.2",
    "drupal/layout_builder_restrictions": "^2.14",
    "drupal/scheduler": "^2.0",
    "drupal/entity_browser": "^2.9",
    "drupal/media_library_form_element": "^2.0",
    "drupal/focal_point": "^2.0",
    "drupal/crop": "^2.3",
    "drupal/legacy_media_widget": "1.0.3",
    "drupal/node_export_old": "2.0.1"
  },
  "extra": {
    "drupal-scaffold": {"locations": {"web-root": "web/"}},
    "installer-paths": {
      "web/core": ["type:drupal-core"],
      "web/modules/contrib/{$name}": ["type:drupal-module"],
      "web/themes/contrib/{$name}": ["type:drupal-theme"]
    }
  },
  "config": {
    "allow-plugins": {
      "composer/installers": true,
      "drupal/core-composer-scaffold": true
    }
  }
}
JSONEOF

cat > "$SCRIPT_DIR/d10-to-d11-jump/.ddev/config.yaml" << 'YAMLEOF'
name: drupal-fixture-d10-d11-jump
type: drupal
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
YAMLEOF

echo "  [OK] d10-to-d11-jump"

# =============================================================================
# Fixture 3: d9-legacy-migration
# Drupal 9.4.2, PHP 8.1, legacy modules (swiftmailer, panelizer, panels)
# =============================================================================
mkdir -p "$SCRIPT_DIR/d9-legacy-migration/.ddev"

cat > "$SCRIPT_DIR/d9-legacy-migration/composer.json" << 'JSONEOF'
{
  "name": "drupal/recommended-project",
  "description": "Fixture: Drupal 9.4.2 legacy migration scenario",
  "type": "project",
  "license": "GPL-2.0-or-later",
  "require": {
    "composer/installers": "^2.2",
    "drupal/admin_toolbar": "^3.0",
    "drupal/core-composer-scaffold": "9.4.2",
    "drupal/core-recommended": "9.4.2",
    "drupal/ctools": "^3.0",
    "drupal/devel": "^4.0",
    "drupal/field_group": "^3.0",
    "drupal/metatag": "^1.0",
    "drupal/panels": "^4.6",
    "drupal/panelizer": "^5.0",
    "drupal/pathauto": "^1.8",
    "drupal/redirect": "^1.6",
    "drupal/swiftmailer": "^2.0",
    "drupal/token": "^1.10",
    "drupal/views_bulk_operations": "^4.0",
    "drupal/xmlsitemap": "^1.0",
    "drupal/search_api": "^1.20",
    "drupal/entity_reference_revisions": "^1.9",
    "drupal/media": "^1.0",
    "drupal/paragraphs": "^1.12"
  },
  "extra": {
    "drupal-scaffold": {"locations": {"web-root": "web/"}},
    "installer-paths": {
      "web/core": ["type:drupal-core"],
      "web/modules/contrib/{$name}": ["type:drupal-module"],
      "web/themes/contrib/{$name}": ["type:drupal-theme"]
    }
  },
  "config": {
    "allow-plugins": {
      "composer/installers": true,
      "drupal/core-composer-scaffold": true
    }
  }
}
JSONEOF

cat > "$SCRIPT_DIR/d9-legacy-migration/.ddev/config.yaml" << 'YAMLEOF'
name: drupal-fixture-d9-legacy
type: drupal
docroot: web
php_version: "8.1"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
YAMLEOF

echo "  [OK] d9-legacy-migration"

# =============================================================================
# Fixture 4: ckeditor4-project
# Drupal 10.2.0, CKEditor 4 module + 2 custom plugins
# =============================================================================
mkdir -p "$SCRIPT_DIR/ckeditor4-project/.ddev"

cat > "$SCRIPT_DIR/ckeditor4-project/composer.json" << 'JSONEOF'
{
  "name": "drupal/recommended-project",
  "description": "Fixture: Drupal 10.2.0 with CKEditor 4 and custom plugins",
  "type": "project",
  "license": "GPL-2.0-or-later",
  "require": {
    "composer/installers": "^2.2",
    "drupal/admin_toolbar": "^3.4",
    "drupal/ckeditor": "^1.0",
    "drupal/ckeditor_accordion": "^2.0",
    "drupal/ckeditor_codemirror": "^3.0",
    "drupal/core-composer-scaffold": "10.2.0",
    "drupal/core-recommended": "10.2.0",
    "drupal/field_group": "^3.4",
    "drupal/metatag": "^2.0",
    "drupal/pathauto": "^1.11",
    "drupal/token": "^1.12",
    "drupal/redirect": "^1.8",
    "drupal/paragraphs": "^1.15",
    "drupal/entity_reference_revisions": "^1.10"
  },
  "extra": {
    "drupal-scaffold": {"locations": {"web-root": "web/"}},
    "installer-paths": {
      "web/core": ["type:drupal-core"],
      "web/modules/contrib/{$name}": ["type:drupal-module"],
      "web/themes/contrib/{$name}": ["type:drupal-theme"]
    }
  },
  "config": {
    "allow-plugins": {
      "composer/installers": true,
      "drupal/core-composer-scaffold": true
    }
  }
}
JSONEOF

cat > "$SCRIPT_DIR/ckeditor4-project/.ddev/config.yaml" << 'YAMLEOF'
name: drupal-fixture-ckeditor4
type: drupal
docroot: web
php_version: "8.2"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
YAMLEOF

echo "  [OK] ckeditor4-project"

# =============================================================================
# Fixture 5: resume-mid-pipeline
# Drupal 10.3.0, interrupted mid-update (8/13 modules updated)
# =============================================================================
mkdir -p "$SCRIPT_DIR/resume-mid-pipeline/.ddev"
mkdir -p "$SCRIPT_DIR/resume-mid-pipeline/reports/drupal-update"

cat > "$SCRIPT_DIR/resume-mid-pipeline/composer.json" << 'JSONEOF'
{
  "name": "drupal/recommended-project",
  "description": "Fixture: Drupal 10.3.0 mid-pipeline resume scenario",
  "type": "project",
  "license": "GPL-2.0-or-later",
  "require": {
    "composer/installers": "^2.2",
    "drupal/address": "^2.0",
    "drupal/admin_toolbar": "^3.4",
    "drupal/core-composer-scaffold": "10.3.0",
    "drupal/core-recommended": "10.3.0",
    "drupal/ctools": "^4.0",
    "drupal/field_group": "^3.4",
    "drupal/metatag": "^2.0",
    "drupal/pathauto": "^1.11",
    "drupal/redirect": "^1.8",
    "drupal/token": "^1.12",
    "drupal/views_bulk_operations": "^4.2",
    "drupal/paragraphs": "^1.15",
    "drupal/entity_reference_revisions": "^1.10"
  },
  "extra": {
    "drupal-scaffold": {"locations": {"web-root": "web/"}},
    "installer-paths": {
      "web/core": ["type:drupal-core"],
      "web/modules/contrib/{$name}": ["type:drupal-module"],
      "web/themes/contrib/{$name}": ["type:drupal-theme"]
    }
  },
  "config": {
    "allow-plugins": {
      "composer/installers": true,
      "drupal/core-composer-scaffold": true
    }
  }
}
JSONEOF

cat > "$SCRIPT_DIR/resume-mid-pipeline/.ddev/config.yaml" << 'YAMLEOF'
name: drupal-fixture-resume
type: drupal
docroot: web
php_version: "8.2"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
YAMLEOF

cat > "$SCRIPT_DIR/resume-mid-pipeline/reports/drupal-update/progress.json" << 'JSONEOF'
{
  "current_phase": "paso-06",
  "current_step": "in_progress",
  "drupal_from": "10.3.0",
  "drupal_to": "10.3.9",
  "modules": {
    "total": 13,
    "updated": 8,
    "blocked": 1,
    "pending": 4
  },
  "deprecated_resolved": false,
  "checkpoint_approved": false,
  "core_updated": false,
  "last_action": "Actualizados 8 de 13 modulos contrib. Bloqueado: drupal/redirect (conflicto de dependencias).",
  "last_snapshot": "2026-03-01T09:45:00Z",
  "next_action": "Resolver bloqueo en drupal/redirect y continuar paso-06",
  "updated": "2026-03-01T10:00:00Z"
}
JSONEOF

echo "  [OK] resume-mid-pipeline"
echo ""
echo "All fixtures created successfully."
echo ""
echo "Verify:"
for f in d10-minor-update d10-to-d11-jump d9-legacy-migration ckeditor4-project resume-mid-pipeline; do
  echo "  === $f ==="
  find "$SCRIPT_DIR/$f" -type f | sort | sed "s|$SCRIPT_DIR/||"
done
