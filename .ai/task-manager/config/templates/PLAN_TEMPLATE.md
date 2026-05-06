---
id: [PLAN-ID]
summary: "[Descripción de una línea sobre lo que logra este plan]"
created: [YYYY-MM-DD]
---

# Plan: [Título Descriptivo del Plan]

## Orden de Trabajo Original (Original Work Order)

[El input del usuario sin modificar que generó este plan, como cita]

## Clarificaciones del Plan

[Solo añadir si fueron necesarias preguntas de clarificación, en formato tabla]

## Resumen Ejecutivo

[Proporciona un resumen de 2-3 párrafos. Incluye:

- Qué logra el plan.
- Por qué se eligió este enfoque.
- Beneficios clave y resultados esperados.]

## Contexto

### Verificación de Entorno

_[Ref: TASK_MANAGER.md 1.1] Antes de definir la arquitectura, verificar:_

- **Versión de Drupal:** [Ej. 10.3.x, 11.1.x]
- **Versión de PHP:** [Ej. 8.1, 8.3]
- **Versión de Drush:** [Ej. 12.x, 13.x]
- **Entorno:** DDEV

### Estado Actual vs Estado Objetivo

[Crea una tabla que compare el estado actual con el estado objetivo en los distintos aspectos de la implementación. Incluye una columna que explique por qué el cambio es necesario.]

Ejemplo:

| Estado Actual                           | Estado Objetivo                        | ¿Por qué?                                  |
| --------------------------------------- | -------------------------------------- | ------------------------------------------ |
| Los usuarios tienen que hacer dos clics | Los usuarios pueden hacer un solo clic | Queremos mejorar la experiencia de usuario |
| El botón es pequeño                     | El botón es más grande                 | Corregir el diseño del sitio               |
| ...                                     | ...                                    | ...                                        |

### Antecedentes

[Contexto adicional, requisitos, restricciones, o intentos fallidos previos.]

### Estrategia: Contrib First

_[Ref: TASK_MANAGER.md 2.6] Analiza si existen módulos contribuidos seguros (Security Advisory Policy) que resuelvan esto._

- **Módulos evaluados:** [Lista]
- **Decisión:** [Usar contrib / Desarrollo custom]
- **Justificación:** [Si es custom, explicar por qué los contrib no sirven]

## Enfoque arquitectónico

[Proporciona una descripción general de la estrategia de implementación, las decisiones arquitectónicas clave y el enfoque técnico. Desglose el proyecto en los componentes o fases principales utilizando ### subtítulos. Agregue un resumen del diagrama de sirena.]

### [Componente/Fase 1: Name]

**Objetivo**: [Qué logra este componente y por qué es importante]

[Explicación detallada y concisa del enfoque de implementación, decisiones técnicas clave, especificaciones y justificación de las opciones de diseño].

- **Servicios:** Nombres de clases e interfaces a crear (si Drupal 8+).
- **Eventos/Hooks:**
  - _Drupal 11.1+:_ Qué atributos `#[Hook]` se implementarán en `src/Hook/`.
  - _Drupal 8.x-10.x:_ Qué hooks procedurales en `.module` delegarán a servicios.
  - _Drupal 7.x:_ Qué hooks procedurales se implementarán.
  - _Event Subscribers:_ Qué eventos del sistema se escucharán (Drupal 8+).
- **Datos:** Cambios en esquema, config entities, state API o variables (según versión).

### [Componente/Fase 2: Name]

**Objetivo**: [Qué logra este componente y por qué es importante]

[Explicación detallada y concisa del enfoque de implementación, decisiones técnicas clave, especificaciones y justificación de las opciones de diseño].

**Estrategia de UI según versión:**

- **Drupal 10.1+:**
  - **Componentes SDC:** Estructura de directorio `components/{grupo}/{nombre}`.
  - **Props:** Definición de esquema en `component.yml`.
  - **Integración:** Cómo se renderizará (Plugin de Bloque, Formatter, etc., devolviendo `['#type' => 'component']`).
- **Drupal 8.x-10.0:**
  - **Plantillas Twig:** Ubicación en `templates/` y estructura de variables.
  - **hook_theme():** Definición en `.module` para registrar plantillas.
  - **Preprocess:** Funciones `template_preprocess_HOOK()` necesarias.
- **Drupal 7.x:**
  - **Archivos .tpl.php:** Ubicación y variables.
  - **hook_theme():** Definición en `.module`.
  - **Preprocess:** Implementación de `hook_preprocess_HOOK()`.

## Consideraciones de Riesgo y Mitigación

<details>
<summary>Riesgos Técnicos</summary>
- **[Riesgo Específico]**: [Descripción]
    - **Mitigación**: [Estrategia, ej. Cache tags específicos, tests de carga]
</details>

<details>
<summary>Riesgos de Implementación</summary>
- **[Riesgo Específico]**: [Descripción]
    - **Mitigación**: [Estrategia]
</details>

## Criterios de Éxito y Testing Strategy

### Criterios Primarios

1. [Resultado medible 1]
2. [Resultado medible 2]
3. [Resultado medible 3]

### Entregables de Pruebas (Ref: TASK_MANAGER.md Sec. 3)

_Definir qué pruebas validarán los criterios anteriores:_

- **Unit/Kernel Tests:** [Listar clases/servicios a testear y qué mocks se necesitan]
- **Behat (BDD):** [Listar escenarios `.feature` que cubren las historias de usuario]
- **Seguridad:** [Confirmar validación de permisos/acceso en las rutas nuevas]

## Documentación Requerida

[Actualizaciones a README.md, documentación de API, o AGENTS.md si aplica]

## Requisitos de Recursos

### Habilidades de Desarrollo

**Backend:**

- Drupal Core (versión detectada en el proyecto)
- PHP (versión requerida por la versión de Drupal)
- _Si Drupal 11.1+:_ OOP Hooks con atributos PHP
- _Si Drupal 8+:_ Servicios, DI, Plugins
- _Si Drupal 7.x:_ Hooks procedurales, APIs de Drupal 7

**Frontend:**

- _Si Drupal 10.1+:_ Single Directory Components (SDC)
- _Si Drupal 8+:_ Sistema de plantillas Twig
- _Si Drupal 7.x:_ Archivos .tpl.php y preprocess hooks
- YML/YAML (para configuración y metadatos)

**Testing:**

- PHPUnit (Unit/Kernel/Functional - adaptar clases base según versión)
- Behat (BDD - agnóstico de versión)

### Infraestructura Técnica

[Herramientas, librerias, frameworks, y sistemas necesarios para el desarrollo y despliegue]

## Estrategia de Integración

[Cómo se integra esto con los sistemas existentes]

### [Categorías Adicionales de Recursos según sea necesario]

[Otros recursos como dependencias externas, acceso a investigación, servicios de terceros, etc.]

## Estrategia de Integración

[Sección opcional: cómo este trabajo se integra con los sistemas existentes]

## Notas

[Sección opcional: cualquier consideración adicional, restricciones o contexto importante]
