# Patrones de Migración de Código Custom — Referencia

> Esta referencia contiene los reemplazos de API más frecuentes en código custom
> durante saltos de versión mayor. El agente `agent-custom-code-fixer` la consulta
> para aplicar correcciones.

## Tabla de contenidos

1. [Drupal 9 → 10: APIs eliminadas](#drupal-9--10-apis-eliminadas)
2. [Drupal 10 → 11: APIs eliminadas](#drupal-10--11-apis-eliminadas)
3. [Drupal 11: Hooks procedurales → OOP](#drupal-11-hooks-procedurales--oop)
4. [PHP 8.1 → 8.2 breaking changes](#php-81--82)
5. [PHP 8.2 → 8.3 breaking changes](#php-82--83)
6. [Patrones comunes en .module / .install](#patrones-comunes)

---

## Drupal 9 → 10: APIs eliminadas

Estas funciones existían deprecated en D9 y se eliminaron en D10.
Si `drupal-check --deprecations` las señala, aplicar el reemplazo.

### Entity API

| Antes (D9 deprecated)                 | Después (D10)                                                         | Notas                   |
| ------------------------------------- | --------------------------------------------------------------------- | ----------------------- |
| `entity_load($type, $id)`             | `\Drupal::entityTypeManager()->getStorage($type)->load($id)`          |                         |
| `entity_load_multiple($type, $ids)`   | `\Drupal::entityTypeManager()->getStorage($type)->loadMultiple($ids)` |                         |
| `entity_create($type, $values)`       | `\Drupal::entityTypeManager()->getStorage($type)->create($values)`    |                         |
| `entity_delete_multiple($type, $ids)` | `\Drupal::entityTypeManager()->getStorage($type)->delete($entities)`  | Necesita cargar primero |
| `node_load($nid)`                     | `\Drupal\node\Entity\Node::load($nid)`                                | O `entityTypeManager`   |
| `user_load($uid)`                     | `\Drupal\user\Entity\User::load($uid)`                                |                         |
| `file_load($fid)`                     | `\Drupal\file\Entity\File::load($fid)`                                |                         |
| `taxonomy_term_load($tid)`            | `\Drupal\taxonomy\Entity\Term::load($tid)`                            |                         |

### Database API

| Antes                   | Después                                   | Notas |
| ----------------------- | ----------------------------------------- | ----- |
| `db_query($sql, $args)` | `\Drupal::database()->query($sql, $args)` |       |
| `db_select($table)`     | `\Drupal::database()->select($table)`     |       |
| `db_insert($table)`     | `\Drupal::database()->insert($table)`     |       |
| `db_update($table)`     | `\Drupal::database()->update($table)`     |       |
| `db_delete($table)`     | `\Drupal::database()->delete($table)`     |       |
| `db_merge($table)`      | `\Drupal::database()->merge($table)`      |       |

### Messages y logging

| Antes                                 | Después                                  | Notas |
| ------------------------------------- | ---------------------------------------- | ----- |
| `drupal_set_message($msg)`            | `\Drupal::messenger()->addMessage($msg)` |       |
| `drupal_set_message($msg, 'error')`   | `\Drupal::messenger()->addError($msg)`   |       |
| `drupal_set_message($msg, 'warning')` | `\Drupal::messenger()->addWarning($msg)` |       |
| `drupal_set_message($msg, 'status')`  | `\Drupal::messenger()->addStatus($msg)`  |       |

### URL y enlaces

| Antes                           | Después                                                  | Notas                  |
| ------------------------------- | -------------------------------------------------------- | ---------------------- |
| `\Drupal::url($route)`          | `Url::fromRoute($route)->toString()`                     | `use Drupal\Core\Url`  |
| `l($text, $url)`                | `Link::fromTextAndUrl($text, $url)`                      | `use Drupal\Core\Link` |
| `drupal_get_path('module', $m)` | `\Drupal::service('extension.list.module')->getPath($m)` |                        |
| `drupal_get_path('theme', $t)`  | `\Drupal::service('extension.list.theme')->getPath($t)`  |                        |

### Rendering

| Antes                          | Después                                                  | Notas                                  |
| ------------------------------ | -------------------------------------------------------- | -------------------------------------- |
| `drupal_render($build)`        | `\Drupal::service('renderer')->render($build)`           | Preferir devolver render array         |
| `drupal_render_root($build)`   | `\Drupal::service('renderer')->renderRoot($build)`       |                                        |
| `check_markup($text, $format)` | `\Drupal\Component\Utility\Xss::filter($text)`           | O `check_markup()` si sigue disponible |
| `format_date($timestamp)`      | `\Drupal::service('date.formatter')->format($timestamp)` |                                        |

### Otros

| Antes                               | Después                                                                | Notas                                        |
| ----------------------------------- | ---------------------------------------------------------------------- | -------------------------------------------- |
| `file_unmanaged_*` (todas)          | `\Drupal::service('file_system')->*`                                   | `copy()`, `move()`, `delete()`, `saveData()` |
| `file_create_url($uri)`             | `\Drupal::service('file_url_generator')->generateAbsoluteString($uri)` |                                              |
| `file_url_transform_relative($url)` | `\Drupal::service('file_url_generator')->transformRelative($url)`      |                                              |
| `unicode_strlen()`                  | `mb_strlen()`                                                          | PHP nativo                                   |
| `unicode_substr()`                  | `mb_substr()`                                                          | PHP nativo                                   |

---

## Drupal 10 → 11: APIs eliminadas

### Hooks y sistema

| Antes                                    | Después                                                | Notas                     |
| ---------------------------------------- | ------------------------------------------------------ | ------------------------- |
| `hook_themes_installed()`                | `\Drupal\Core\Theme\Event\ThemesInstalledEvent`        | Event subscriber          |
| `hook_themes_uninstalled()`              | `\Drupal\Core\Theme\Event\ThemesUninstalledEvent`      | Event subscriber          |
| `hook_modules_installed()`               | `\Drupal\Core\Extension\Event\ModulesInstalledEvent`   | Event subscriber          |
| `hook_modules_uninstalled()`             | `\Drupal\Core\Extension\Event\ModulesUninstalledEvent` | Event subscriber          |
| `\Drupal::entityManager()` (si persiste) | `\Drupal::entityTypeManager()`                         | Eliminado definitivamente |

### Theme system

| Antes                              | Después                        | Notas                                    |
| ---------------------------------- | ------------------------------ | ---------------------------------------- |
| Tema base `classy`                 | Starterkit `generate-theme`    | `php core/scripts/drupal generate-theme` |
| Tema base `stable`                 | Starterkit `generate-theme`    | Mismo mecanismo                          |
| `template_preprocess_*` en .module | Mover a .theme o usar Hook OOP |                                          |

### Render y respuesta

| Antes                                                  | Después                                  | Notas                      |
| ------------------------------------------------------ | ---------------------------------------- | -------------------------- |
| `AccessResult::allowedIf()` sin `->addCacheContexts()` | Siempre añadir cache contexts/tags       | Más estricto en D11        |
| `\Drupal::service('path.alias_manager')`               | `\Drupal::service('path_alias.manager')` | Renombrado                 |
| `\Drupal::service('path.current')`                     | `\Drupal::service('path.current')`       | Sin cambio, pero verificar |

---

## Drupal 11: Hooks procedurales → OOP

En Drupal 11, los hooks se pueden implementar como métodos de clase con atributos PHP.
Los hooks procedurales siguen funcionando pero se recomienda migrar a OOP.

### Antes (procedural en .module)

```php
/**
 * Implements hook_form_alter().
 */
function mi_modulo_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if ($form_id === 'node_article_form') {
    $form['title']['#required'] = TRUE;
  }
}
```

### Después (OOP con Hook attribute en D11)

```php
// src/Hook/MiModuloHooks.php
namespace Drupal\mi_modulo\Hook;

use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Hook\Attribute\Hook;

class MiModuloHooks {

  #[Hook('form_alter')]
  public function formAlter(array &$form, FormStateInterface $form_state, string $form_id): void {
    if ($form_id === 'node_article_form') {
      $form['title']['#required'] = TRUE;
    }
  }
}
```

### Reglas para la migración

1. Crear clase en `src/Hook/{ModuleName}Hooks.php`
2. Namespace: `Drupal\{module_name}\Hook`
3. Un método por hook, con atributo `#[Hook('hook_name')]`
4. El nombre del método es libre (no necesita prefijo del módulo)
5. Los parámetros son idénticos al hook procedural
6. Eliminar la función procedural del .module tras migrar

### Hooks que NO migran a OOP (permanecen procedurales)

- `hook_install()` / `hook_uninstall()` — se quedan en `.install`
- `hook_update_N()` — se quedan en `.install`
- `hook_requirements()` — se queda en `.install`
- `hook_schema()` — se queda en `.install`

---

## PHP 8.1 → 8.2

| Cambio                                       | Impacto                                     | Fix                                                    |
| -------------------------------------------- | ------------------------------------------- | ------------------------------------------------------ |
| Propiedades dinámicas deprecated             | `$object->newProp = 'x'` genera deprecation | Declarar propiedad o usar `#[\AllowDynamicProperties]` |
| `${var}` en strings deprecated               | `"text ${var} more"`                        | Usar `"text {$var} more"`                              |
| `utf8_encode()` / `utf8_decode()` deprecated |                                             | Usar `mb_convert_encoding($s, 'UTF-8', 'ISO-8859-1')`  |
| `Readonly` classes                           | Nueva feature                               | No es breaking, pero útil                              |

## PHP 8.2 → 8.3

| Cambio                                          | Impacto                            | Fix                           |
| ----------------------------------------------- | ---------------------------------- | ----------------------------- |
| Return type de `json_validate()`                | Nueva función built-in             | No breaking (nueva API)       |
| `Randomizer` mejoras                            | Nueva API                          | No breaking                   |
| Class constants pueden ser typed                | Nueva feature                      | No breaking                   |
| `array_sum()` / `array_product()` más estrictos | Warning si array tiene non-numeric | Filtrar arrays antes de pasar |

---

## Patrones comunes

### Inyección de dependencias en lugar de `\Drupal::service()`

Cuando un fix reemplaza `\Drupal::servicio()` global, el agente evalúa si el
contexto permite inyección de dependencias (clases con constructor, plugins,
controllers). Si es posible, preferir DI:

```php
// Antes
$messenger = \Drupal::messenger();

// Después (en una clase con DI)
public function __construct(
  protected readonly MessengerInterface $messenger,
) {}
```

Las funciones en `.module` (procedurales) NO tienen DI disponible — ahí
`\Drupal::service()` es correcto.

### Namespace imports

Al añadir una nueva clase en un reemplazo, verificar que el `use` statement
exista al inicio del fichero. Si no, añadirlo:

```php
use Drupal\Core\Url;
use Drupal\Core\Link;
use Drupal\Core\Messenger\MessengerInterface;
```
