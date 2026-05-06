# Matriz de Compatibilidad de Versiones — Referencia Detallada

> Para la estrategia de actualización incremental, ver `references/incremental-strategy.md`.

---

## Drupal 9 → Drupal 10

### Prerrequisitos

- PHP 8.1+ (mínimo), 8.2+ (recomendado)
- Composer 2.x
- Drush 11.6+ para D9, Drush 12.x para D10
- Todos los módulos contrib deben tener versión compatible con D10
- Código custom libre de APIs deprecated en D9

### Ruta de actualización (INCREMENTAL)

**⚠️ IMPORTANTE:** Esta skill requiere estar en **Drupal 9.5.x** (última minor) antes de saltar a D10.

#### Fase 1: Llegar a D9.5.x (si no estás ya)

1. Ejecutar `paso-03-version-objetivo.sh` (sin flags)
2. Actualizar módulos puente para D9.5.x
3. Actualizar core a D9.5.11 (o última disponible)
4. Validar que todo funciona
5. Ejecutar `drupal-check` en código custom
6. Resolver deprecation warnings de D9

#### Fase 2: Saltar a D10.x (solo después de Fase 1)

1. Verificar PHP 8.1+ (8.2+ recomendado)
2. Ejecutar `paso-03-version-objetivo.sh --major-jump`
3. Actualizar módulos contrib a versiones D10-compatible
4. Subir constraint de core a `^10`
5. Actualizar Drush a `^12`
6. Validación final

#### ¿Por qué requiere D9.5.x primero?

- D9.5.x es la última minor con todos los bug fixes
- D9.5.x incluye deprecation warnings que preparan para D10
- Menor riesgo: validar en dos pasos en lugar de uno grande
- Algunos módulos tienen releases específicos para D9.5 que facilitan migración a D10

**Nota:** Drupal 9 llegó a EOL (End of Life) en noviembre 2023, pero la estrategia incremental sigue siendo válida para minimizar riesgo.

### Cambios críticos D9 → D10

- jQuery UI eliminado del core → Usar librerías alternativas
- CKEditor 4 eliminado → Migrar a CKEditor 5
- Claro es el nuevo tema admin por defecto
- Olivero es el nuevo tema frontend por defecto
- Aggregator module eliminado del core
- Color module eliminado del core
- HAL module eliminado del core
- QuickEdit module eliminado del core
- RDF module eliminado del core

### Módulos commonly problemáticos en D9→D10

- `drupal/swiftmailer` → Reemplazar por `drupal/symfony_mailer`
- `drupal/panelizer` → Evaluar alternativas (Layout Builder)
- `drupal/ctools` → Verificar versión 4.x compatible
- `drupal/pathauto` → Actualizar a 1.12+
- Cualquier módulo que dependa de jQuery UI

---

## Drupal 10.x → 10.y (Minor/Patch)

### Drupal 10.0-10.2 → 10.3+

- PHP 8.2+ requerido (8.1 ya no soportado en 10.3)
- Drush 12.4+ requerido
- `theme_suggestions` hook cambios menores

### Drupal 10.3 → 10.4

- PHP 8.2+ (sin cambios)
- Navegación experimental → estable
- Recipes API (experimental)

### Drupal 10.4 → 10.5

- Última minor antes de D11
- Deprecation notices para código que no será compatible con D11
- PHP 8.2+ mínimo

### Notas para minor updates

- Generalmente seguro con `composer update -W`
- Revisar release notes por deprecaciones
- Los patches al core tienen mayor riesgo de fallar en minor jumps

---

## Drupal 10 → Drupal 11

### Prerrequisitos

- PHP 8.3+ (obligatorio)
- Composer 2.7+
- Drush 13.x
- **Drupal 10.6.x como punto de partida (REQUERIDO por esta skill)**
- Cero deprecation warnings en código custom

### Ruta de actualización (INCREMENTAL)

**⚠️ IMPORTANTE:** Esta skill requiere estar en **Drupal 10.6.x** (última minor) antes de saltar a D11.

#### Fase 1: Llegar a D10.6.x (si no estás ya)

1. Ejecutar `paso-03-version-objetivo.sh` (sin flags)
2. Actualizar módulos puente para D10.6.x
3. Actualizar core a D10.6.x
4. Validar que todo funciona
5. Ejecutar `drupal-check --drupal-11` en código custom
6. Resolver deprecation warnings

#### Fase 2: Saltar a D11.x (solo después de Fase 1)

1. Verificar PHP 8.3+
2. Ejecutar `paso-03-version-objetivo.sh --major-jump`
3. Verificar compatibilidad D11 de todos los módulos contrib
4. Actualizar módulos puente D11
5. Subir constraint de core a `^11`
6. Actualizar Drush a `^13`
7. Validación final

#### ¿Por qué requiere D10.6.x primero?

- D10.4+ incluye deprecation warnings críticos para D11
- D10.6.x es la última minor que recibe security updates
- Algunos módulos tienen releases específicos para D10.6 que facilitan migración a D11
- Menor riesgo: validar en dos pasos en lugar de uno grande

### Cambios críticos D10 → D11

- PHP 8.3+ obligatorio
- Todas las APIs deprecated en D10 eliminadas
- Symfony 7.x (desde 6.x)
- PHPUnit 10+ (desde 9)
- Theme Starterkit changes
- Varios módulos movidos de core a contrib

### Módulos commonly problemáticos en D10→D11

- Verificar TODOS los módulos contra el D11 compatibility tracker:
  https://www.drupal.org/docs/upgrading-drupal/upgrading-from-drupal-10-to-drupal-11

---

## Drush Compatibility

| Drupal    | Drush mínimo | Drush recomendado |
| --------- | ------------ | ----------------- |
| 9.5.x     | 11.x         | 11.6+             |
| 10.0-10.2 | 12.0         | 12.4+             |
| 10.3-10.5 | 12.4         | 12.5+             |
| 11.0+     | 13.0         | 13.x latest       |

---

## PHP End of Life

| PHP | EOL      | Notas                       |
| --- | -------- | --------------------------- |
| 8.1 | Nov 2025 | Ya no recibe security fixes |
| 8.2 | Dec 2026 | Solo security fixes         |
| 8.3 | Nov 2027 | Active support              |
| 8.4 | Nov 2028 | Active support              |

**Recomendación:** Siempre subir a la última PHP soportada por el Drupal objetivo.
