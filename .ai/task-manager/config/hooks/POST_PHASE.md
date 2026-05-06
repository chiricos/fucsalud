# POST_PHASE Hook

Antes de marcar esta fase como completada, **debes autoevaluar** todo el código y la configuración generados frente a los siguientes estándares **NO-NEGOCIABLES** del proyecto. Si fallas en alguno, **corrígelo inmediatamente**.

**IMPORTANTE:** Las verificaciones deben adaptarse a la **versión de Drupal del proyecto** (verificada en TASK_MANAGER.md 1.1).

## 1. PHP Estricto y Tipado (Ref: 2.1)

**Aplicable a:** Drupal 8+ con PHP 7.1+, obligatorio en Drupal 11+ con PHP 8.3+

- [ ] ¿Todos los archivos PHP comienzan con `declare(strict_types=1);`? (Si la versión de PHP lo soporta)
- [ ] ¿Todos los métodos tienen tipos de retorno explícitos (incluyendo `void`)? (PHP 7.1+)
- [ ] ¿Todos los argumentos de función tienen tipos definidos? (Según capacidades de la versión de PHP)

## 2. Arquitectura Moderna según Versión (Ref: 2.2, 2.3)

### Para Drupal 11.1+:

- [ ] **Hooks OOP:** ¿Se han usado **Atributos PHP** (`#[Hook]`) en clases dedicadas en `src/Hook/` en lugar de funciones en archivos `.module`?
- [ ] **Lógica:** ¿Se ha evitado poner lógica de negocio en Controladores/Formularios y se ha delegado a Servicios inyectables?
- [ ] **Inyección de Dependencias:**
  - [ ] ¿Se ha eliminado cualquier llamada estática a `\Drupal::service()` o `\Drupal::config()` dentro de clases?
  - [ ] ¿Se usa `create(ContainerInterface $container)` para inyectar dependencias?
  - [ ] ¿Las inyecciones están tipadas contra **Interfaces** y no clases concretas?

### Para Drupal 8.x - 10.x:

- [ ] **Hooks Procedurales:** ¿Los hooks en `.module` delegan inmediatamente su lógica a Servicios?
- [ ] **Lógica:** ¿Se ha evitado poner lógica de negocio en Controladores/Formularios y se ha delegado a Servicios inyectables?
- [ ] **Inyección de Dependencias:**
  - [ ] ¿Se minimiza el uso de `\Drupal::service()` y se prefiere DI en clases?
  - [ ] ¿Se usa `create(ContainerInterface $container)` para inyectar dependencias en Plugins, Controladores y Formularios?
  - [ ] ¿Las inyecciones están tipadas contra **Interfaces**?

### Para Drupal 7.x:

- [ ] **Hooks Procedurales:** ¿Los hooks están correctamente implementados en `.module` o `.install`?
- [ ] **Organización:** ¿La lógica compleja está encapsulada en funciones auxiliares reutilizables?
- [ ] **Variables:** ¿Se usa `variable_get()`/`variable_set()` correctamente para configuración?

## 3. Frontend según Versión (Ref: 2.4)

### Para Drupal 10.1+:

- [ ] ¿Toda nueva UI está implementada como **Single Directory Components (SDC)**?
- [ ] ¿Se ha evitado registrar nuevos `hook_theme` para componentes nuevos?
- [ ] ¿Los render arrays retornan `['#type' => 'component', ...]` en lugar de plantillas Twig sueltas?
- [ ] ¿Existe `component.yml` con esquemas completos para `props` y `slots`?

### Para Drupal 8.x - 10.0:

- [ ] ¿Las plantillas Twig están correctamente ubicadas en `templates/`?
- [ ] ¿Se ha registrado `hook_theme()` correctamente para las nuevas plantillas?
- [ ] ¿Están definidas las variables esperadas en las plantillas?
- [ ] ¿Se usan funciones `preprocess` cuando es necesario manipular variables?

### Para Drupal 7.x:

- [ ] ¿Los archivos `.tpl.php` están correctamente ubicados?
- [ ] ¿Se ha registrado `hook_theme()` correctamente?
- [ ] ¿Se implementan los `hook_preprocess_HOOK()` necesarios?
- [ ] ¿Las variables están correctamente preparadas para las plantillas?

## 4. Seguridad (Ref: 2.5)

- [ ] ¿Se usa el módulo **Key** (`drupal/key`) para cualquier credencial o token?
- [ ] **Verificación crítica:** ¿Garantizas que NO hay secretos, claves o tokens harcodeados en el código o config?

## 5. Estrategia de Pruebas (Ref: 3)

**Aplicable a:** Todas las versiones de Drupal (adaptar clases base según versión)

- [ ] ¿Existe una prueba unitaria (Unit) o de integración (Kernel) para cada servicio o lógica creada?
- [ ] ¿Se han creado los escenarios `.feature` de Behat correspondientes a las historias de usuario del plan?
- [ ] ¿Están mockeadas las dependencias en los tests unitarios? (Drupal 8+)
- [ ] ¿Se han ejecutado todas las pruebas y han pasado exitosamente?
- [ ] **Drupal 7.x:** ¿Se usan SimpleTest o tests funcionales apropiados para la versión?

**Si alguna respuesta es "NO", refactoriza el código ahora mismo.**

## 6. Supervisión de la Ejecución

### Seguimiento del Progreso

Actualiza la lista de tareas del documento del plan para añadir el estado de cada tarea y fase. Una vez que una fase haya sido completada y validada, y antes de pasar a la siguiente, actualiza el _blueprint_ y añade un emoji ✅ delante de su título.
Añade un emoji ✔️ delante de todas las tareas de esa fase y actualiza su estado a `completed` (_completado_).

### Actualización del Estado de las Tareas

Transiciones de estado válidas:

- `pending` → `in-progress` (cuando el agente comienza)
- `in-progress` → `completed` (ejecución satisfactoria)
- `in-progress` → `failed` (error en la ejecución)
- `failed` → `in-progress` (intento de reintento)
