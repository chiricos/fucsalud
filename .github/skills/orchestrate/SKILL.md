---
name: orchestrate
disable-model-invocation: true
description: Orquesta un flujo multi-agente de 6 fases (explorar, refinar, planificar, ejecutar, implementar tests, verificar) para abordar tareas complejas sin saturar la ventana de contexto. Solo el usuario puede invocar esta skill.
---

# Orchestrate - Flujo Multi-Agente

## Proposito

Esta skill orquesta un pipeline de 6 fases para resolver tareas complejas de desarrollo.
Cada fase se ejecuta en un subagente independiente (Task tool con general agent) para mantener
la ventana de contexto del agente principal limpia y enfocada en la coordinacion.

## Restriccion de uso

Esta skill SOLO puede ser invocada directamente por el usuario. Ningun agente o subagente
debe cargarla automaticamente. Si eres un subagente, IGNORA esta skill por completo.

## Flujo de ejecucion

El usuario invoca esta skill acompanada de un prompt que describe lo que quiere hacer.
El prompt del usuario es el input principal de todo el pipeline.

```
USUARIO --> [Prompt original]
               |
               v
         FASE 0.5: SELECCION DE AGENTE EXPLORADOR
         El agente principal busca entre los agentes disponibles
         cual es el mas adecuado para explorar el codebase. Pregunta
         al usuario con question tool. Si no hay candidato, usa general.
               |
               v
         FASE 1: EXPLORADOR
         (subagente seleccionado o general - lectura + bash)
         Busca archivos afectados, analiza codebase
               |
               v
         [Resumen markdown de descubrimientos]
               |
               v
         FASE 1.5: SELECCION DE AGENTE REFINADOR
         El agente principal busca entre los agentes disponibles
         cual es el mas adecuado para refinar la peticion. Pregunta
         al usuario con question tool. Si no hay candidato, usa general.
               |
               v
         FASE 2: REFINADOR (bucle x2 iteraciones)
         (subagente seleccionado o general - lectura)
         Iteracion 1: Formula preguntas basadas en resumen
                       --> question tool --> respuestas del usuario
         Iteracion 2: Adapta preguntas basandose en todo el contexto acumulado
                       --> question tool --> respuestas del usuario
               |
               v
         [Resumen + Todas las Q&A acumuladas]
               |
               v
         FASE 2.5: SELECCION DE AGENTE PLANIFICADOR
         El agente principal busca entre los agentes disponibles
         cual es el mas adecuado para planificar la implementacion. Pregunta
         al usuario con question tool. Si no hay candidato, usa general.
               |
               v
         FASE 3: PLANIFICADOR
         (subagente seleccionado o general - lectura)
         Genera plan de accion estructurado (sin codigo fuente)
               |
               v
         [Plan de accion markdown]
               |
               v
          FASE 3.5: SELECCION DE AGENTE EJECUTOR
          El agente principal busca entre los agentes disponibles
          cual es el mas adecuado para la tarea. Pregunta al usuario
          con question tool. Si no hay candidato, usa general.
                |
                v
          FASE 4: EJECUTOR
          (subagente seleccionado o general)
          Implementa el plan paso a paso. NO escribe tests.
                |
                v
          [Lista de archivos modificados + resumen de cambios]
                |
                v
          FASE 4.3: SELECCION DE AGENTE IMPLEMENTADOR DE TESTS
          El agente principal busca entre los agentes disponibles
          cual tiene capacidades de testing. Pregunta al usuario
          con question tool. Si no hay candidato, usa general.
                |
                v
          FASE 4.5: IMPLEMENTADOR DE TESTS
          (subagente seleccionado o general)
          Analiza el codigo de produccion y escribe tests:
          unitarios, Kernel, Behat, E2E segun contexto.
          Ejecuta los tests y verifica que pasan.
                |
                v
          [Informe de tests implementados + resultado de ejecucion]
                |
                v
          FASE 4.7: SELECCION DE AGENTE VERIFICADOR
          El agente principal busca entre los agentes disponibles
          cual tiene capacidades de verificacion/QA. Pregunta
          al usuario con question tool. Si no hay candidato, usa general.
                |
                v
          FASE 5: BUCLE VERIFICACION & CORRECCION (max 2 iteraciones)
          Iteracion:
            [A] VERIFICADOR (subagente seleccionado o general - solo lectura)
                Ejecuta lint, suite de tests completa, E2E segun contexto
                Genera informe markdown de resultados
                     |
                  APROBADO? --> SI --> Pipeline completado
                     |
                     NO
                     v
            [B] CORRECTOR (mismo agente de Fase 4)
                Recibe informe de fallos y corrige codigo de produccion o tests
                     |
                     v
            Vuelve a [A] (max 2 iteraciones totales)
                     |
                  Sigue fallando despues de 2 iteraciones?
                     v
            Escala al usuario con informe detallado
                |
                v
          [Pipeline completado]
```

## Instrucciones detalladas por fase

### FASE 0.5: Seleccion de agente explorador

El agente principal (NO un subagente) debe:

1. Analizar el prompt del usuario para entender que tipo de exploracion se requiere
   (lectura de codebase, busqueda de patrones, analisis de dependencias, etc.).
2. Revisar la lista de agentes disponibles (los que aparecen en las descripciones
   del Task tool y en el menu de `@`).
3. Evaluar si alguno de los agentes disponibles es un candidato adecuado para
   explorar el codebase (por sus capacidades de lectura, bash, o analisis de codigo).
4. Si encuentra uno o mas candidatos, presentarlos al usuario con la herramienta
   `question`:
   - Cada agente candidato como opcion, con su nombre y descripcion
   - Una opcion adicional: "Usar agente general (por defecto)"
5. Si NO encuentra ningun candidato especifico, informar al usuario y usar
   directamente el agente `general`.
6. Almacenar la decision como `SELECTED_EXPLORER`.

### FASE 1: Explorador

Lanza el subagente seleccionado (o `general` por defecto). El prompt del subagente debe incluir:

1. La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Explorador. SOLO puedes usar herramientas de
lectura: read, glob, grep, y bash UNICAMENTE para comandos de solo lectura (ls,
tree, git log, git diff, find, cat). NUNCA uses Write, Edit, ni comandos bash que
creen o modifiquen ficheros. Si lo haces, el pipeline queda invalidado. Tu output
debe ser exclusivamente el resumen de exploracion en markdown. Nada mas.
```

2. El prompt original del usuario (textual, sin modificar).
3. Las instrucciones del archivo `references/explorer-prompt.md` de esta skill.

El subagente devuelve un **resumen en markdown** con todos los descubrimientos.
Almacena este resumen como variable `EXPLORER_SUMMARY` para las fases siguientes.

**Invocacion:**

```
Task({
  subagent_type: SELECTED_EXPLORER,
  description: "Fase 1: Explorar codebase",
  prompt: "<INSTRUCCION CRITICA arriba>\n\n<instrucciones de explorer-prompt.md>\n\n## Peticion del usuario\n<prompt original>"
})
```

### FASE 1.5: Seleccion de agente refinador

El agente principal (NO un subagente) debe:

1. Analizar el `EXPLORER_SUMMARY` para entender que tipo de refinamiento se necesita
   (preguntas sobre UI/UX, arquitectura, logica de negocio, integraciones, etc.).
2. Revisar la lista de agentes disponibles (los que aparecen en las descripciones
   del Task tool y en el menu de `@`).
3. Evaluar si alguno de los agentes disponibles es un candidato adecuado para
   formular preguntas de refinamiento (por sus capacidades de analisis o dominio especifico).
4. Si encuentra uno o mas candidatos, presentarlos al usuario con la herramienta
   `question`:
   - Cada agente candidato como opcion, con su nombre y descripcion
   - Una opcion adicional: "Usar agente general (por defecto)"
5. Si NO encuentra ningun candidato especifico, informar al usuario y usar
   directamente el agente `general`.
6. Almacenar la decision como `SELECTED_REFINER`.

### FASE 2: Refinador (bucle de 2 iteraciones)

Se ejecutan 2 iteraciones secuenciales. Cada iteracion lanza el subagente seleccionado en la Fase 1.5.

**Iteracion 1:**

El subagente recibe:

- El prompt original del usuario (COMPLETO, con referencias externas intactas)
- El `EXPLORER_SUMMARY`
- Las instrucciones del archivo `references/refiner-prompt.md`
- Indicacion de que es la iteracion 1 de 2
- La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Refinador. SOLO puedes usar las herramientas
`read` (para referencias externas) y `webfetch` (para URLs). NUNCA uses Write,
Edit, Bash ni ninguna herramienta que modifique ficheros o ejecute comandos.
Si lo haces, el pipeline queda invalidado. Tu output debe ser exclusivamente
el bloque JSON con preguntas y, si hay referencias externas, el campo
`external_references_analysis`. Nada mas.
```

El subagente analiza el contexto y genera una bateria de preguntas (minimo 5, sin maximo).
Devuelve las preguntas como un JSON estructurado.

**Despues de recibir las preguntas del subagente**, el agente principal las presenta al usuario
usando la herramienta `question`. Cada pregunta debe tener opciones sugeridas por el subagente
mas la opcion de respuesta libre.

Almacena las preguntas y respuestas como `REFINEMENT_QA_1`.

**Iteracion 2:**

El subagente recibe:

- Todo lo anterior PLUS `REFINEMENT_QA_1` (preguntas + respuestas de la iteracion 1)
- Indicacion de que es la iteracion 2 de 2
- Instruccion de adaptar: puede profundizar en temas de la iteracion 1, pivotar a nuevos
  aspectos descubiertos, o cubrir areas que las respuestas del usuario revelaron como importantes
- La misma instruccion de refuerzo anti-implementacion del inicio de la Iteracion 1

Se repite el mismo flujo: subagente genera preguntas, agente principal las presenta con
`question`, se almacenan como `REFINEMENT_QA_2`.

**Formato de preguntas del subagente:**

El subagente debe devolver las preguntas en este formato JSON para que el agente principal
pueda construir las llamadas a `question`:

```json
{
  "questions": [
    {
      "header": "Titulo corto (max 30 chars)",
      "question": "La pregunta completa y detallada",
      "options": [
        { "label": "Opcion 1", "description": "Explicacion de la opcion" },
        { "label": "Opcion 2", "description": "Explicacion de la opcion" }
      ],
      "multiple": false
    }
  ]
}
```

### FASE 2.5: Seleccion de agente planificador

El agente principal (NO un subagente) debe:

1. Analizar el `EXPLORER_SUMMARY` y las Q&A del refinador para entender que tipo de
   planificacion se requiere (arquitectura, migracion, integracion de APIs, UI, etc.).
2. Revisar la lista de agentes disponibles (los que aparecen en las descripciones
   del Task tool y en el menu de `@`).
3. Evaluar si alguno de los agentes disponibles es un candidato adecuado para
   generar el plan de accion (por sus capacidades de analisis tecnico o dominio especifico).
4. Si encuentra uno o mas candidatos, presentarlos al usuario con la herramienta
   `question`:
   - Cada agente candidato como opcion, con su nombre y descripcion
   - Una opcion adicional: "Usar agente general (por defecto)"
5. Si NO encuentra ningun candidato especifico, informar al usuario y usar
   directamente el agente `general`.
6. Almacenar la decision como `SELECTED_PLANNER`.

### FASE 3: Planificador

Lanza el subagente seleccionado (o `general` por defecto). El prompt del subagente debe incluir:

1. La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Planificador. SOLO puedes usar la herramienta
`read` para consultar ficheros de codigo del proyecto si necesitas confirmar un
patron existente. NUNCA uses Write, Edit, Bash, webfetch ni ninguna herramienta
que modifique ficheros, ejecute comandos o consuma referencias externas.
Si lo haces, el pipeline queda invalidado. Tu output debe ser exclusivamente
el plan de accion en markdown. Nada mas.
```

2. El prompt filtrado del usuario (sin referencias externas)
3. El `EXPLORER_SUMMARY`
4. `REFINEMENT_QA_1` y `REFINEMENT_QA_2` completas
5. Las instrucciones del archivo `references/planner-prompt.md`

El subagente devuelve un **plan de accion** estructurado en markdown.
Almacena como `ACTION_PLAN`.

### FASE 3.5: Seleccion de agente ejecutor

El agente principal (NO un subagente) debe:

1. Analizar el `ACTION_PLAN` para entender que tipo de trabajo se requiere.
2. Revisar la lista de agentes disponibles (los que aparecen en las descripciones
   del Task tool y en el menu de `@`).
3. Evaluar si alguno de los agentes disponibles es un candidato adecuado para
   ejecutar el plan (por sus capacidades, descripcion, y permisos).
4. Si encuentra uno o mas candidatos, presentarlos al usuario con la herramienta
   `question`:
   - Cada agente candidato como opcion, con su nombre y descripcion
   - Una opcion adicional: "Usar agente general (por defecto)"
5. Si NO encuentra ningun candidato especifico, informar al usuario y usar
   directamente el agente `general`.
6. Almacenar la decision como `SELECTED_EXECUTOR`.

### FASE 4: Ejecutor

Lanza el subagente seleccionado (o `general` por defecto). El prompt debe incluir:

1. La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Ejecutor. Tu mision es implementar el plan de
accion de codigo de produccion. PROHIBIDO escribir tests (es trabajo de Fase 4.5).
PROHIBIDO usar webfetch o leer imagenes/PDFs. PROHIBIDO implementar funcionalidad
no contemplada en el plan. Si algo no esta en el plan pero parece necesario,
documentalo en el informe final pero NO lo implementes.
```

2. El prompt filtrado del usuario (sin referencias externas)
3. El `ACTION_PLAN` completo
4. El resumen de todas las Q&A (`REFINEMENT_QA_1` + `REFINEMENT_QA_2`)
5. Las instrucciones del archivo `references/executor-prompt.md`

El subagente implementa el plan paso a paso, usando TodoWrite para tracking,
y consultando al usuario con `question` antes de operaciones destructivas.

Al finalizar, el subagente debe devolver:

- Lista de **archivos creados o modificados**
- Resumen de las tareas completadas, canceladas y fallidas

Almacena este resultado como `EXECUTION_RESULT`.

### FASE 4.3: Seleccion de agente implementador de tests

El agente principal (NO un subagente) debe:

1. Analizar el `EXECUTION_RESULT` para entender que tipo de codigo se ha generado
   (logica de negocio, servicios, plugins de Drupal, controladores, frontend, etc.).
2. Revisar la lista de agentes disponibles (los que aparecen en las descripciones
   del Task tool y en el menu de `@`).
3. Identificar candidatos cuya **descripcion mencione testing, PHPUnit, Behat,
   Playwright, Cypress, QA, o implementacion de tests**.
4. Si encuentra uno o mas candidatos, presentarlos al usuario con la herramienta
   `question`:
   - Cada agente candidato como opcion, con su nombre y descripcion
   - Una opcion adicional: "Usar agente general (por defecto)"
5. Si NO encuentra ningun candidato especifico, informar al usuario y usar
   directamente el agente `general`.
6. Almacenar la decision como `SELECTED_TEST_IMPLEMENTER`.

### FASE 4.5: Implementador de tests

Lanza el subagente seleccionado (o `general` por defecto). El prompt debe incluir:

1. La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Implementador de Tests. SOLO puedes modificar
o crear archivos de test. NUNCA toques el codigo de produccion. Tu output debe
ser los archivos de test implementados y un informe de resultados. Nada mas.
```

2. El prompt filtrado del usuario (sin referencias externas)
3. El `ACTION_PLAN` completo
4. El `EXECUTION_RESULT` (lista de archivos creados o modificados por el ejecutor)
5. El resumen de todas las Q&A (`REFINEMENT_QA_1` + `REFINEMENT_QA_2`)
6. Las instrucciones del archivo `references/test-implement-prompt.md`

El subagente analiza el codigo de produccion, implementa la suite de tests completa
(unitarios, Kernel, Behat, E2E segun el contexto), ejecuta los tests y devuelve
un informe de lo implementado y el resultado de ejecucion.

Almacena este resultado como `TEST_IMPLEMENTATION_RESULT`.

### FASE 4.7: Seleccion de agente verificador

El agente principal (NO un subagente) debe:

1. Revisar la lista de agentes disponibles (los que aparecen en las descripciones
   del Task tool y en el menu de `@`).
2. Identificar candidatos cuya **descripcion mencione verificacion, QA, ejecucion
   de tests, calidad de codigo, o herramientas como Playwright, Puppeteer, Jest, Cypress**.
3. Si encuentra uno o mas candidatos, presentarlos al usuario con la herramienta
   `question`:
   - Cada agente candidato como opcion con su nombre y descripcion
   - Una opcion adicional: "Usar agente general (por defecto)"
4. Si NO encuentra ningun candidato, informar al usuario y usar directamente
   el agente `general`.
5. Almacenar la decision como `SELECTED_TESTER`.

### FASE 5: Bucle Verificacion & Correccion (max 2 iteraciones)

Esta fase se ejecuta en un **bucle** de maximo 2 iteraciones completas.
Cada iteracion consta de dos pasos secuenciales: verificador y (si hay fallos) corrector.

**Variables a mantener:**

- `TEST_ITERATION`: contador de iteracion actual (empieza en 1)
- `LAST_TEST_REPORT`: ultimo informe del verificador

#### Paso A: Verificador

Lanza el subagente seleccionado (o `general` por defecto) con permisos de **solo lectura
y ejecucion** (sin escritura de codigo). El prompt debe incluir:

1. La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Verificador. SOLO puedes leer archivos y
ejecutar comandos de verificacion (lint, tests, build). NUNCA uses Write, Edit
ni comandos bash que creen o modifiquen ficheros. No corrijas fallos: solo
detectalos, documentalos y reportalos. Tu output debe ser exclusivamente el
informe de verificacion en markdown. Nada mas.
```

2. El prompt original del usuario
3. El `ACTION_PLAN`
4. El `EXECUTION_RESULT` (lista de archivos de produccion modificados)
5. El `TEST_IMPLEMENTATION_RESULT` (lista de tests implementados en Fase 4.5)
6. La iteracion actual (`TEST_ITERATION`)
7. Las instrucciones del archivo `references/tester-prompt.md`

```
Task({
  subagent_type: SELECTED_TESTER,
  description: "Fase 5: Verificacion (iteracion X)",
  prompt: "<instrucciones de tester-prompt.md>\n\n## Plan de accion\n<ACTION_PLAN>\n\n## Cambios implementados\n<EXECUTION_RESULT>\n\n## Tests implementados\n<TEST_IMPLEMENTATION_RESULT>\n\n## Peticion original\n<prompt original>\n\n## Iteracion: X de 2"
})
```

El subagente devuelve el **informe de verificacion** en formato markdown.
Almacena como `LAST_TEST_REPORT`.

**Si el informe indica estado APROBADO o APROBADO CON ADVERTENCIAS:**

- Muestra el informe al usuario
- El pipeline finaliza con exito

**Si el informe indica estado FALLIDO:**

- Muestra el informe al usuario brevemente
- Si `TEST_ITERATION` < 2, continua con el Paso B
- Si `TEST_ITERATION` >= 2, escala al usuario (ver seccion "Escalado")

#### Paso B: Corrector (mismo agente de Fase 4)

Lanza el mismo subagente que se uso en la Fase 4 (`SELECTED_EXECUTOR`). El prompt debe incluir:

1. La siguiente instruccion de refuerzo, incluida SIEMPRE al inicio del prompt:

```
INSTRUCCION CRITICA: Eres el agente Corrector (modo correccion de Fase 5).
Corrige UNICAMENTE los fallos reportados en el informe de verificacion.
PROHIBIDO escribir tests, PROHIBIDO introducir funcionalidad adicional,
PROHIBIDO usar webfetch o leer imagenes/PDFs. Si hay tests que corregir,
no los toques: el agente de Fase 4.5 lo gestionara en la siguiente iteracion.
```

2. El prompt filtrado del usuario (sin referencias externas)
3. El `ACTION_PLAN`
4. El `EXECUTION_RESULT`
5. El `LAST_TEST_REPORT` con los fallos detectados
6. Las instrucciones del archivo `references/executor-prompt.md`

Actualiza `EXECUTION_RESULT` con los nuevos cambios realizados por el corrector.
Incrementa `TEST_ITERATION` en 1. Vuelve al Paso A.

#### Escalado tras 2 iteraciones fallidas

Si despues de 2 iteraciones completas el estado sigue siendo FALLIDO:

1. Muestra al usuario el ultimo `LAST_TEST_REPORT` completo.
2. Informa: "El pipeline ha alcanzado el limite de 2 iteraciones de correccion
   sin lograr que todos los tests pasen."
3. Usa la herramienta `question` para preguntar como proceder:

```
question({
  questions: [{
    header: "Fallos sin resolver",
    question: "Los tests siguen fallando despues de 2 intentos de correccion. Como deseas proceder?",
    options: [
      { label: "Revisar manualmente", description: "Detener el pipeline y revisar los fallos tu mismo" },
      { label: "Ignorar y finalizar", description: "Aceptar el estado actual y dar el pipeline por completado" },
      { label: "Reintentar una vez mas", description: "Ejecutar una tercera iteracion de test y correccion" }
    ]
  }]
})
```

## Notas de implementacion para el agente principal

### Gestion de contexto

- Cada fase se ejecuta en un subagente INDEPENDIENTE via Task tool.
- El agente principal actua como COORDINADOR: recibe resultados resumidos de cada
  fase y los pasa como input a la siguiente.
- NUNCA leas archivos del codebase directamente desde el agente principal durante
  la orquestacion. Eso es trabajo de los subagentes.
- Los resultados de cada subagente son strings resumidos. Si un subagente devuelve
  demasiado contenido, pide que resuma.

### Filtrado de referencias externas

El prompt del usuario puede contener referencias a ficheros pesados, imagenes, URLs
o contenido externo que SOLO debe ser procesado por el agente Refiner (Fase 2).

**Reglas de filtrado:**

1. **Fase 2 (Refiner)**: Recibe el prompt del usuario COMPLETO, sin filtrar, con
   todas las referencias intactas. Es el UNICO agente autorizado a leer referencias
   externas.

2. **Fases 3, 4 y 5 (Planner, Executor, Tester)**: Reciben el prompt del usuario
   FILTRADO, sin referencias a ficheros pesados. En su lugar, estos agentes trabajan
   con el analisis textual extraido por el Refiner en `external_references_analysis`.

**Tipos de referencias que deben filtrarse:**

- Menciones con `@fichero` (ej: `@mockup.png`, `@design-spec.pdf`)
- Rutas a imagenes locales (ej: `./assets/banner.jpg`, `/path/to/screenshot.png`)
- Extensiones: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp`, `.pdf`
- URLs de Figma (ej: `https://www.figma.com/file/...` o `https://www.figma.com/design/...`)
- URLs de sitios web (ej: `https://example.com/docs`, `http://api.example.com`)
- Respuestas de MCPs que contengan contenido binario o JSON pesado

**Tipos de referencias que NO deben filtrarse:**

- Referencias a codigo del proyecto (ej: `src/components/Button.tsx:45`)
- Rutas a ficheros de codigo (ej: `./lib/utils.ts`, `/api/endpoints.js`)
- Menciones textuales en el contexto de la peticion

**Ejemplo de filtrado:**

Prompt original del usuario:

```
Implementa el componente Login segun el mockup @login-screen.png
y la paleta de colores de https://www.figma.com/file/abc123
Usa la utilidad de validacion en src/utils/validation.ts:67
```

Prompt filtrado para Fases 3, 4, 4.5 y 5:

```
Implementa el componente Login segun el mockup [referencia filtrada]
y la paleta de colores de [referencia filtrada]
Usa la utilidad de validacion en src/utils/validation.ts:67
```

La informacion extraida de las referencias filtradas estara disponible en
`REFINEMENT_QA_1`, `REFINEMENT_QA_2` y el campo `external_references_analysis`
del Refiner.

### Manejo de errores

- Si un subagente falla, informa al usuario y pregunta si desea reintentar esa fase.
- Si el usuario cancela durante las preguntas (Fase 2), detener el pipeline y
  mostrar el resumen de lo recopilado hasta el momento.
- Si la Fase 4 (ejecucion) falla parcialmente, el TodoWrite deberia reflejar
  que tareas se completaron y cuales quedaron pendientes.
- Si la Fase 5 falla tras 2 iteraciones, escala al usuario con el informe detallado
  y presenta opciones (revisar manualmente, ignorar, reintentar).

### Presentacion de preguntas (Fase 2)

Cuando el subagente de refinamiento devuelve las preguntas en formato JSON,
el agente principal debe:

1. Parsear el JSON de preguntas del subagente.
2. Construir la llamada a `question` tool con el formato correcto.
3. Esperar las respuestas del usuario.
4. Formatear las respuestas como texto legible para pasarlas al siguiente subagente.

### Transparencia

- Al inicio de cada fase, informa al usuario que fase se esta ejecutando.
- Al final de la Fase 1, muestra un resumen breve del `EXPLORER_SUMMARY`.
- Al final de la Fase 3, muestra el `ACTION_PLAN` al usuario antes de proceder.
- Pide confirmacion explicita antes de iniciar la Fase 4 (ejecucion).
- Al final de la Fase 4, muestra el `EXECUTION_RESULT` al usuario antes de iniciar la Fase 4.5.
- Al inicio de la Fase 4.5, informa que se va a implementar la suite de tests.
- Al inicio de la Fase 5, informa que iteracion de verificacion se esta ejecutando.
- Al finalizar el pipeline (con exito o escalado), muestra un resumen final del
  estado de los tests.
