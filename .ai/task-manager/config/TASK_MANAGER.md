# Información General del Gestor de Tareas

Este documento contiene información importante que es común a todos los comandos /task:\* para asistentes de IA.

## Tipos de Documentos

Las órdenes de trabajo (abreviadas como **WO**) son prompts complejos para tareas de programación, organización o gestión creados por un usuario. Las órdenes de trabajo son independientes entre sí y **no pueden compartir contexto**. Por definición, diferentes órdenes de trabajo pueden ejecutarse de manera independiente.

Cada orden de trabajo tiene un **plan** asociado. El plan es un documento completo que destaca todos los aspectos del trabajo necesarios para cumplir los objetivos de la orden de trabajo.

Cada plan se divide en **tareas**. Cada tarea es una unidad lógica de trabajo con un único propósito y se resuelve utilizando una única habilidad. Todas las tareas forman parte de un plan. Las tareas pueden tener dependencias con otras tareas, lo que ocurre cuando una tarea no puede trabajarse (o completarse) antes de que alguna(s) otra(s) tarea(s) hayan sido completadas.

## Estructura de Directorios

Para encontrar un documento de plan a partir de su ID utiliza el siguiente comando (sustituye {planId} por el ID, como 06):

```shell
find .ai/task-manager/{plans,archive} -name "plan-[0-9][0-9]*--*.md" -type f -exec grep -l "^id: \?{planId}$" {} \;
```

Los planes y tareas están almacenados como archivos Markdown con una cabecera YAML. Todos ellos se encuentran en la carpeta `.ai/task-manager/` en la raíz del repositorio.

Los planes se organizan de la siguiente forma:

    .ai/
      task-manager/
        plans/           # Planes activos (en progreso)
          01--authentication-provider/
            plan-01--authentication-provider.md
            tasks/
              01--create-project-structure.md
              02--implement-authorization.md
              03--this-example-task.md
              04--create-tests.md
              05--update-documentation.md
        archive/         # Planes completados (ejecutados con éxito)
          05--user-management/
            plan-05--user-management.md
            tasks/
              01--create-user-model.md
              02--implement-crud-operations.md
              03--add-validation.md

Observa que en la carpeta `.ai/task-manager/plans/` tenemos una subcarpeta por plan.
Cada subcarpeta contiene el documento del plan y tiene un nombre con el patrón `[ID]--[nombre-corto-del-plan]`. El ID es autoincremental.
El documento del plan tiene un nombre con el patrón `plan-[ID]--[nombre-corto-del-plan].md`.

Finalmente, todas las tareas se encuentran en una subcarpeta `tasks`. Cada tarea tiene un nombre siguiendo el patrón `[ID-incremental]--[nombre-corto-de-la-tarea].md`. Los IDs de las tareas son autoincrementales dentro de cada plan y cada plan comienza sus tareas desde el 01.

## Ciclo de Vida del Plan y Sistema de Archivo

Los planes siguen un ciclo de vida que mantiene organizada la zona de trabajo:

1.  **Planes Activos**: Cuando se crean, los planes se colocan en el directorio `plans/`, donde permanecen mientras se trabaja en ellos.

2.  **Planes Completados**: Tras la ejecución satisfactoria de un blueprint (mediante `/tasks:execute-blueprint`), el directorio completo del plan se mueve automáticamente de `plans/` a `archive/`.

3.  **Directorio Archive**: El directorio `archive/` sirve como almacenamiento permanente para el trabajo completado. Esta separación mantiene el espacio de trabajo activo limpio, a la vez que conserva los planes completados para referencia futura.

El sistema de archivo proporciona varios beneficios:

- **Organización del espacio de trabajo**: Los planes activos permanecen accesibles mientras que el trabajo completado no ocupa espacio en el área activa.
- **Referencia histórica**: Los planes completados y sus tareas están disponibles para consulta o aprendizaje.
- **Gestión automática**: No se requiere intervención manual: el archivado ocurre automáticamente tras la finalización correcta.

---

## 1. ⚙️ CONTEXTO GLOBAL Y STACK

### 1.1. Verificación del Entorno

Antes de iniciar cualquier tarea, el Agente **DEBE** verificar el entorno actual del proyecto:

1.  **Entorno de Desarrollo:** DDEV.
2.  **Versión de Drupal:** Consultar `composer.json` → campo `drupal/core-recommended` o `drupal/core`. Alternativamente, ejecutar `ddev status` para verificar la versión en un entorno DDEV.
3.  **Versión de PHP:** Verificar en `.ddev/config.yaml` → campo `php_version` o requisitos en `composer.json`.
4.  **Versión de Drush:** Consultar `composer.json` → paquete `drush/drush`.

### 1.2. Stack Base

- **Core:** Drupal (versión determinada en el paso 1.1).
- **PHP:** Versión compatible con la versión de Drupal detectada.
- **Entorno:** DDEV.
- **Comandos de Drush:**
  - Todos los comandos de Drush deben pasar por `ddev`. Ejemplo: `ddev drush cr`.
- **Generación de Código:**
  - Drush 10+: Usar `drush generate` para generar código base.
  - El Agente debe adaptar la sintaxis según la versión de Drush detectada.
- **Pruebas:** PHPUnit (Unit/Kernel/Functional) y Behat (BDD), adaptando las clases base según la versión de Drupal.
- **Control:** Módulo Drupal MCP (si está disponible). El Agente debe verificar si existe algún servidor MCP configurado y accesible, y avisar si no funciona.

### 1.3. Adaptación por Versión

El Agente debe ajustar sus recomendaciones y código generado según la versión de Drupal detectada:

- **Drupal 7.x:** Enfoque basado en hooks procedurales, uso de `variable_get/set`, sin clases de servicios.
- **Drupal 8.x - 9.x:** Uso de servicios, inyección de dependencias, hooks en `.module`, clases PSR-4.
- **Drupal 10.x:** Igual que 8.x/9.x, con mayor énfasis en APIs modernas y deprecación de APIs antiguas.
- **Drupal 11.x+:** Soporte para OOP Hooks (atributos PHP), requisitos de PHP 8.3+, APIs más estrictas.

---

## 2. 🛡️ ESTÁNDARES DE DESARROLLO (NO-NEGOCIABLE)

### 2.1. PHP ESTRICTO Y TIPADO

1.  **Modo Estricto Mandatorio:** Todo archivo PHP **DEBE** comenzar con `declare(strict_types=1);` como primera instrucción tras la etiqueta de apertura.

- _Nota Crítica:_ Si `ddev drush generate` omite esta línea, el Agente debe inyectarla inmediatamente antes de escribir cualquier otra lógica.

2.  **Tipado Total:** Todos los argumentos de métodos, propiedades de clase y valores de retorno deben tener tipos explícitos (`string`, `int`, `void`, `?array`, etc.). No se permite confiar en la inferencia de tipos implícita.

### 2.2. ARQUITECTURA: SERVICIOS Y HOOKS MODERNOS

1.  **Lógica Desacoplada:** Toda la lógica de negocio debe residir en **Servicios** inyectables. Los Controladores, Plugins y Formularios deben actuar solo como orquestadores que delegan a estos servicios.
2.  **Implementación de Hooks (según versión de Drupal):**

    **Para Drupal 11.1+:**
    - **Preferencia OOP:** Se debe priorizar la implementación de hooks como métodos de clase usando el atributo PHP `#[Hook]` en el directorio `src/Hook/`.
    - **Prohibición de Procedural:** Evitar implementar hooks como funciones en archivos `.module` (ej. `function mymodule_entity_insert`) salvo excepciones justificadas.
    - **Excepción Controlada:** Se permiten funciones procedurales únicamente en archivos `.install` (`hook_install`, `hook_update_N`) cuando el contenedor de servicios no esté plenamente disponible, pero su lógica debe ser mínima.

    **Para Drupal 8.x - 10.x:**
    - **Hooks Procedurales:** Los hooks se implementan como funciones en archivos `.module` o `.install`.
    - **Delegar a Servicios:** La lógica debe delegarse inmediatamente a servicios inyectados mediante `\Drupal::service()` o el contenedor, cuando esté disponible.
    - **Minimizar Lógica:** Mantener los hooks lo más ligeros posible, actuando solo como puntos de entrada.

    **Para Drupal 7.x:**
    - **Hooks Procedurales Tradicionales:** Toda la implementación se realiza mediante funciones en archivos `.module` o `.install`.
    - **Encapsular Lógica:** Cuando sea posible, encapsular lógica compleja en funciones auxiliares reutilizables.

### 2.3. INYECCIÓN DE DEPENDENCIAS (DI)

**Aplicable a Drupal 8.x+** (Drupal 7.x no soporta DI nativa)

1.  **Cero Statics en Clases:** Prohibido el uso de llamadas estáticas a localizadores de servicios globales (ej. `\Drupal::service()`, `\Drupal::config()`) dentro de clases que soporten inyección de dependencias.
2.  **Patrón de Fábrica:** Se permite y exige el uso de métodos estáticos de fábrica `create(ContainerInterface $container)` únicamente para instanciar la clase e inyectar dependencias en el constructor.
3.  **Tipado por Interfaz:** Las inyecciones deben tiparse contra **Interfaces** (ej. `EntityTypeManagerInterface`), nunca contra clases concretas.
4.  **Configuración de Servicios:**
    - **Drupal 10.x+:** Preferir `autowire: true` en `services.yml` para simplificar la definición de servicios.
    - **Drupal 8.x - 9.x:** Definir explícitamente las dependencias en `services.yml` si `autowire` no está disponible o genera conflictos.
5.  **Hooks Procedurales:** Cuando se usen hooks procedurales (`.module`), se permite usar `\Drupal::service()` para obtener servicios, pero la lógica debe delegarse inmediatamente al servicio.

### 2.4. INTERFAZ DE USUARIO: SINGLE DIRECTORY COMPONENTS (SDC)

**Aplicable a Drupal 10.1+** (SDC se introdujo en Drupal 10.1 de forma estable)

**Para Drupal 10.1+:**

1.  **SDC Preferido:** Todo nuevo elemento de UI **DEBE** implementarse como **Single Directory Component** cuando sea posible.
2.  **Prohibición de `hook_theme`:** No se deben registrar nuevos hooks de tema en el `theme registry` para nuevos componentes.
3.  **Estrategia de Implementación en Backend:**
    - Para **Bloques y Controladores**: El método `build()` debe retornar un render array con la estructura `['#type' => 'component', '#component' => 'mod:comp', '#props' => [...]]`.
    - Para **Vistas y Campos**: Se deben crear **Plugins de Estilo de Vistas** o **Formatters de Campo** personalizados que retornen componentes SDC, evitando el uso de plantillas Twig sueltas en `templates/`.
4.  **Estructura:**
    - Ubicación: `web/themes/custom/NOMBRE_TEMA/components/{GRUPO}/{NOMBRE}` o `docroot/themes/custom/NOMBRE_TEMA/components/{GRUPO}/{NOMBRE}`.
    - Validación: Es obligatorio incluir `component.yml` con esquemas JSON completos para `props` y `slots`.

**Para Drupal 8.x - 10.0:**

1.  **Plantillas Twig Tradicionales:** Usar `hook_theme()` para registrar plantillas y el sistema de plantillas Twig estándar.
2.  **Organización:** Mantener las plantillas en el directorio `templates/` del módulo o tema.
3.  **Reutilización:** Crear plantillas base reutilizables y usar `include`/`extend` de Twig para compartir código.

**Para Drupal 7.x:**

1.  **Sistema de Temas de Drupal 7:** Usar `hook_theme()` con funciones de template o archivos `.tpl.php`.
2.  **Preprocess Hooks:** Implementar `hook_preprocess_HOOK()` para preparar variables.

### 2.5. SEGURIDAD Y GESTIÓN DE CREDENCIALES

1.  **Mandato del Módulo Key:** Es **OBLIGATORIO** utilizar el módulo contribuido **Key** (`drupal/key`) para gestionar cualquier dato sensible. Esto aplica estrictamente a:

- Claves privadas y certificados.
- Nombres de usuario y contraseñas de servicios externos.
- Tokens de API (Bearer tokens, API Keys).
- URLs de endpoints de servicios (cuando no son públicas/estáticas).

2.  **Prohibición de Hardcoding:** Está **ESTRICTAMENTE PROHIBIDO** almacenar secretos en texto plano dentro del código, comentarios, archivos de configuración exportables (`.yml`) o variables de estado (`State API`).
3.  **Implementación:** El Agente debe configurar el módulo Key como dependencia (`dependencies` en `info.yml`) y utilizar el servicio `KeyRepositoryInterface` para recuperar los valores de forma segura en tiempo de ejecución.

### 2.6. ESTRATEGIA DE IMPLEMENTACIÓN: CONTRIB FIRST

1.  **Búsqueda Mandatoria:** Antes de proponer o implementar cualquier solución de código personalizado, el Agente **DEBE** realizar una búsqueda exhaustiva de módulos contribuidos existentes que satisfagan los requisitos, total o parcialmente.
2.  **Jerarquía de Selección:** Al evaluar módulos candidatos, la decisión se basará estrictamente en el siguiente orden de prioridad:

- **1. Cobertura de Seguridad (CRÍTICO):** Se debe priorizar absolutamente el módulo que cuente con la cobertura de la "Security advisory policy" (Icono del escudo en Drupal.org).
- **2. Popularidad y Mantenimiento:** Entre los módulos seguros, se elegirá aquel con mayor número de descargas reportadas y uso activo reciente.

3.  **Justificación de Custom:** Solo se permite escribir código personalizado:

- 1. Si no existe un módulo contrib que cumpla los requisitos.
- 2. Si se necesita implementar plugins o hooks nuevos tanto del core como de modulos contrib.
- 3. Si se necesita decorar un servicio del core o de un módulo contrib.
- 4. Si la adaptación del módulo contrib requiere un esfuerzo desproporcionado comparado con una solución a medida limpia.

---

## 3. 🧪 ESTRATEGIA DE PRUEBAS

1.  **Cobertura Obligatoria:** Todo código personalizado debe estar cubierto por pruebas unitarias (con `UnitTestCase`) o de integración (con `KernelTestBase`), dependiendo de la naturaleza de la lógica.
2.  **Mocks para Dependencias:** En pruebas unitarias, todas las dependencias inyectadas deben ser simuladas (mocked) para garantizar el aislamiento de la lógica bajo prueba.
3.  **Trazabilidad SDD -> BDD:** Cada "User Story" o requisito funcional definido en el **plan** debe tener un escenario correspondiente en un archivo `.feature` de Behat en `tests/behat/local/features`.
4.  **Ejecución Continua:** Las pruebas deben ejecutarse automáticamente después de cada implementación para garantizar la integridad del código.
5.  **Cobertura de Código:** Se debe mantener una cobertura de código del 100% para todo el código personalizado, sin excepciones.
6.  **Pruebas de Seguridad:** Cualquier código que maneje datos sensibles o autenticación debe incluir pruebas específicas para validar su seguridad.
7.  **Revisión de Pruebas:** Antes de considerar una implementación como completa, el Agente debe revisar manualmente las pruebas para asegurarse de que cubren todos los casos relevantes y no contienen errores lógicos.
8.  **Documentación de Pruebas:** Cada prueba debe incluir comentarios claros que expliquen su propósito, los casos que cubre y cualquier configuración especial necesaria para su ejecución.
9.  **Mantenimiento de Pruebas:** Las pruebas deben mantenerse actualizadas con cualquier cambio en la lógica del código. Si se modifica o elimina código, las pruebas relacionadas deben ser revisadas y ajustadas en consecuencia.
10. **Pruebas de Regresión:** Se deben ejecutar pruebas de regresión completas después de cualquier cambio significativo para garantizar que no se introduzcan errores en funcionalidades existentes.
11. **Pruebas de Usuario Final:** Para cualquier funcionalidad que afecte la interfaz de usuario, se deben incluir pruebas funcionales con Behat que simulen la experiencia del usuario final.
