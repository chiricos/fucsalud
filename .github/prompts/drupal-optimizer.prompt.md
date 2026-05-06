---
description: |
model: Claude Sonnet 4.6 (copilot)
argument-hint: Ruta o nombre del directorio a analizar (ej. "ai-toolkit", "../skills/commit-helper"). Si no se indica, el agente detecta las opciones disponibles.
---

$ARGUMENTS


# Drupal Optimizer — Instrucciones para la IA

## Propósito

Analizar la estructura y contenido de skills/prompts/agentes de IA para:

1. Identificar oportunidades de optimización de tokens
2. Detectar redundancias y contenido duplicado
3. Evaluar la estructura organizativa
4. Detectar patrones que generan premium requests innecesarios
5. Generar informe accionable con mejoras específicas

## Reglas de Análisis

### 1. Alcance del análisis

- **Incluir**: Archivos markdown (.md), instrucciones, prompts, documentación que se carga en contexto de IA
- **Excluir**: Scripts ejecutables (.sh, .py, .js), archivos de configuración (.json, .yaml), código fuente
- **Foco**: Contenido que consume tokens del contexto de la IA

### 2. Nunca modificar archivos

Este comando es **solo de análisis**. NUNCA:

- Editar archivos existentes
- Crear archivos fuera del informe
- Aplicar optimizaciones automáticamente
- Hacer commits de cambios

**Solo genera el informe** y deja que el usuario decida qué hacer.

### 3. Métricas de tokens

Para estimar tokens:

- **Regla general**: 1 token ≈ 0.75 palabras en español/inglés
- **Equivalencia**: 100 palabras ≈ 133 tokens
- Usa `wc -w` para contar palabras y multiplica por 1.33

### 4. Qué es una premium request

Una **premium request** es cada invocación al modelo de IA de alto coste. Se genera:

- Por cada **turno de conversación** (mensaje del usuario + respuesta del agente)
- Por cada **tool call** ejecutada (read_file, run_in_terminal, etc.)
- Por cada **subagente** lanzado
- Por cada **iteración de bucle** en un flujo de trabajo

Patrones en markdown que provocan premium requests extra:

- Instrucciones del tipo "pregunta al usuario si..." → turnos de aclaración adicionales
- "Si no está claro..." sin criterio de decisión → el agente pide confirmación
- Referencias a archivos externos que hay que cargar → tool calls de lectura
- Lógica secuencial sin puntos de salida temprana → iteraciones innecesarias
- Instrucciones que invocan subagentes sin condición de necesidad
- Fases de verificación redundantes que podrían fusionarse

## Proceso de Análisis

### Fase 0: Detección del Directorio Objetivo (Automático)

> Esta fase es crítica en entornos con múltiples proyectos (workspaces multi-carpeta en VS Code). No asumas que el CWD del terminal es el directorio correcto a analizar.

```bash
# Listar el directorio actual y sus carpetas inmediatas para saber dónde estamos
pwd
ls -d */
```

Con esa información, aplica estas reglas de prioridad:

- **Si el usuario indicó una ruta** como argumento al invocar el slash command → úsala directamente como `$TARGET_DIR` (resuelve relativa al CWD si es relativa)
- **Si el argumento coincide con una carpeta del directorio actual** → usa esa carpeta
- **Si no hay argumento y el directorio actual contiene archivos markdown o una carpeta `src/`/`registry/`/`agents/`** → el CWD es probablemente el objetivo; confirma con el usuario mostrando la ruta completa
- **Si no hay argumento y el directorio actual no parece una skill/prompt** → lista las subcarpetas disponibles y **pregunta al usuario** cuál quiere analizar antes de continuar

Una vez identificado el objetivo, fija:

- `$TARGET_DIR` — ruta absoluta al directorio raíz a analizar (ej. `/Users/alexismartinez/Documents/Sites/dev-modules/ai-toolkit`)

A partir de este punto, **todos los comandos usan `$TARGET_DIR` como base absoluta**, nunca `.` o rutas relativas.

**Checkpoint 0**: Si no puedes determinar el directorio correcto, **pregunta al usuario** antes de continuar.

---

### Fase 1: Reconocimiento (Automático)

1. **Identificar estructura del proyecto**

   ```bash
   # TARGET_DIR ya fijado en Fase 0 — nunca usar "." directamente
   TARGET_DIR="$TARGET_DIR"

   # Encontrar todos los archivos markdown
   find "$TARGET_DIR" -type f -name "*.md" | sort
   ```

2. **Analizar tamaño de archivos**

   ```bash
   # Contar palabras por archivo
   for f in $(find "$TARGET_DIR" -name "*.md"); do
     echo "$f: $(wc -w < "$f") palabras"
   done

   # Contar líneas totales
   find "$TARGET_DIR" -name "*.md" -exec wc -l {} + | tail -1
   ```

3. **Leer archivos principales**
   - SKILL.md o archivo principal de entrada
   - Todos los archivos en `agents/` si existe
   - Todos los archivos en `references/` si existe
   - README.md si contiene instrucciones para IA

4. **Calcular consumo total**
   - Suma de palabras de todos los archivos markdown
   - Conversión a tokens estimados
   - Identificar archivos más pesados (top 5)

### Fase 2: Análisis de Redundancia (Automático)

1. **Detectar bloques duplicados**
   - Buscar líneas idénticas que aparecen en múltiples archivos
   - Identificar headers o secciones repetidas
   - Calcular tokens desperdiciados por duplicación

2. **Buscar patrones comunes**

   ```bash
   # Headers repetidos
   grep -r "^>" "$TARGET_DIR" --include="*.md" | sort | uniq -c | sort -rn

   # Frases de advertencia repetidas
   grep -ri "no ejecutar\|nunca\|siempre" "$TARGET_DIR" --include="*.md"
   ```

3. **Identificar información de referencia mezclada**
   - Tablas de datos
   - Listas de comandos/scripts
   - Documentación técnica detallada
   - Troubleshooting guides

### Fase 3: Análisis Estructural (Automático)

1. **Evaluar granularidad de archivos**
   - Identificar archivos desproporcionadamente grandes (>800 palabras)
   - Verificar si agrupan múltiples responsabilidades
   - Detectar secciones que podrían separarse

2. **Evaluar jerarquía de información**
   - ¿Qué se carga siempre vs bajo demanda?
   - ¿Hay información crítica vs referencia mezcladas?
   - ¿La estructura facilita carga selectiva?

3. **Analizar formato de contenido**
   - Tablas ASCII vs Markdown estándar
   - Bloques de código largos vs referencias
   - Ejemplos inline vs archivos separados

### Fase 4: Análisis de Premium Requests (Automático)

1. **Detectar patrones de aclaración forzada**

   ```bash
   # Buscar instrucciones que obligan al agente a preguntar al usuario
   grep -rni "pregunta al usuario\|ask the user\|solicita confirmación\|pide al usuario\|si no está claro\|if unclear\|verify with user" "$TARGET_DIR" --include="*.md"
   ```

2. **Detectar cargas de archivos externos**

   ```bash
   # Referencias a archivos que el agente tendrá que leer
   grep -rni "lee el archivo\|read_file\|carga el archivo\|ver references/\|ver agents/" "$TARGET_DIR" --include="*.md"
   ```

3. **Detectar invocaciones de subagentes**

   ```bash
   # Patrones que lanza subagentes
   grep -rni "runSubagent\|launch.*agent\|sub.agent\|delega en\|lanza un agente" "$TARGET_DIR" --include="*.md"
   ```

4. **Evaluar fases del flujo de trabajo**
   - Contar el número de fases/pasos secuenciales definidos
   - Identificar pasos que podrían fusionarse sin perder funcionalidad
   - Detectar verificaciones redundantes entre fases
   - Evaluar si hay condiciones de salida temprana definidas

5. **Detectar ausencia de contexto autocontenido**
   - ¿El archivo principal incluye toda la información necesaria?
   - ¿Hay secciones que dicen "consulta X para más detalle" sin incluirlo?
   - ¿Las instrucciones son ambiguas y pueden provocar peticiones de aclaración?

6. **Estimar tool calls mínimas necesarias**
   - Contar tool calls inevitables (las del flujo principal)
   - Identificar tool calls evitables (las provocadas por instrucciones ambiguas)
   - Calcular ratio: tool calls evitables / total estimado

### Fase 5: Identificación de Quick Wins (Automático)

Buscar oportunidades de optimización con:

- **Alto impacto** (>100 tokens de ahorro o >1 premium request evitada por ejecución)
- **Bajo esfuerzo** (<1 hora de trabajo)
- **Bajo riesgo** (no afecta funcionalidad)

Categorías a evaluar:

1. Redundancia en headers/footers
2. Información de referencia que puede moverse
3. Formatos ineficientes (tablas ASCII, etc.)
4. Contenido obsoleto o innecesario
5. Instrucciones que pueden consolidarse
6. Patrones de aclaración que pueden eliminarse con instrucciones más precisas
7. Cargas de archivos externos que pueden inlinearse
8. Fases que pueden fusionarse para reducir iteraciones

### Fase 6: Generación del Informe (Automático)

Crear `OPTIMIZATION_REPORT.md` en el directorio raíz analizado con:

#### Estructura del informe

```markdown
# Informe de Optimización — [Nombre del Proyecto]

**Fecha**: [fecha actual]
**Directorio analizado**: [ruta]
**Objetivo**: Reducir consumo de tokens y premium requests manteniendo funcionalidad

---

## Resumen Ejecutivo

### Métricas Actuales — Tokens

[Tabla con archivos, tokens, % del total]

### Métricas Actuales — Premium Requests

| Métrica                            | Valor actual | Valor óptimo |
| ---------------------------------- | ------------ | ------------ |
| Fases/pasos del flujo              | N            | N            |
| Tool calls estimadas por ejecución | N            | N            |
| Patrones de aclaración detectados  | N            | 0            |
| Archivos externos que se cargan    | N            | N            |
| Subagentes invocados               | N            | N            |

### Impacto por Optimización

[Tabla con categorías, ahorro en tokens, reducción de requests, esfuerzo, ROI]

---

## Análisis de la Estructura Actual

### ✅ Fortalezas

[Lista de aspectos bien implementados]

### ⚠️ Puntos de Mejora — Tokens

[Lista de problemas detectados con impacto]

### ⚠️ Puntos de Mejora — Premium Requests

[Lista de patrones detectados que generan requests innecesarios]

---

## Análisis de Premium Requests

### Patrones de aclaración detectados

[Instrucciones que obligan al agente a pedir confirmación al usuario]

### Cargas de archivos externos innecesarias

[Archivos que se leen en cada ejecución pero podrían inlinearse o eliminarse]

### Fases fusionables

[Pasos secuenciales que podrían combinarse sin perder funcionalidad]

### Subagentes y su justificación

[Lista de invocaciones a subagentes: ¿son necesarias o evitables?]

---

## Quick Wins: Mejoras de Alto Impacto y Bajo Esfuerzo

### 🎯 Quick Win #1: [Título]

**Ahorro estimado**: X tokens / Y premium requests por ejecución
**Tiempo de implementación**: X minutos
**Dificultad**: ⭐ [nivel]
**Tipo**: [Tokens / Premium Requests / Ambos]

#### Ubicación del problema

[Archivos y líneas específicas]

#### Análisis

[Descripción del problema]

#### Solución propuesta

[Código o cambios específicos]

#### Archivos a modificar

[Tabla con archivos, líneas, acciones]

#### Validación

[Checklist de verificación]

---

[Repetir para cada Quick Win]

---

## Optimizaciones de Medio Plazo (Recomendadas)

[Mejoras que requieren más esfuerzo pero mayor impacto]

---

## Validación de la Estructura General

### Evaluación: [Adecuada / Requiere Cambios]

[Análisis de la arquitectura general]

---

## Recomendaciones Finales

### Implementación Sugerida

[Plan en fases con tiempos y prioridades]

### Métricas de Éxito

| Métrica                       | Antes | Objetivo |
| ----------------------------- | ----- | -------- |
| Tokens totales                | X     | Y        |
| Tool calls por ejecución      | X     | Y        |
| Turnos de aclaración promedio | X     | 0        |

---

## Conclusión

[Resumen y próximos pasos]
```

## Criterios de Calidad del Informe

### El informe DEBE incluir

1. **Métricas concretas**
   - Números exactos de tokens/palabras
   - Estimación de tool calls por ejecución
   - Número de patrones de aclaración detectados
   - Porcentajes de ahorro y tiempos estimados de implementación

2. **Ubicaciones específicas**
   - Archivos exactos con rutas completas
   - Números de línea cuando sea relevante
   - Secciones específicas identificadas

3. **Quick Wins identificados**
   - Mínimo 3 quick wins si existen oportunidades
   - Cada uno con ahorro >50 tokens O >1 premium request evitable por ejecución
   - Indicar si el quick win afecta a tokens, premium requests o ambos
   - Soluciones concretas y accionables

4. **Ejemplos de código**
   - Mostrar "antes" y "después" en cambios propuestos
   - Incluir snippets completos cuando sea útil

5. **Análisis de premium requests**
   - Inventario de tool calls inevitables vs evitables
   - Patrones de aclaración con propuesta de reescritura
   - Evaluación de subagentes: ¿necesarios o fusionables?

6. **Validación de estructura**
   - Evaluación clara: ¿la estructura es adecuada?
   - Justificación de la evaluación
   - Recomendaciones estructurales si aplica

### El informe NO debe

1. ❌ Ser vago o genérico ("podrías optimizar aquí")
2. ❌ Sugerir cambios sin cuantificar ahorro
3. ❌ Proponer cambios que rompen funcionalidad
4. ❌ Ser excesivamente largo (máximo 500 líneas)
5. ❌ Incluir cambios aplicados (solo análisis)

## Comunicación con el Usuario

### Al iniciar el análisis

```
🔍 Analizando estructura de la skill en: [ruta]

Escaneando archivos markdown...
- Encontrados: N archivos
- Total de palabras: X
- Tokens estimados: Y

Iniciando análisis detallado...
```

### Durante el análisis

Reportar progreso brevemente:

- ✅ Fase 1: Reconocimiento completado
- ✅ Fase 2: Análisis de redundancia completado
- ✅ Fase 3: Análisis estructural completado
- ✅ Fase 4: Análisis de premium requests completado (N patrones detectados)
- ✅ Fase 5: Quick Wins identificados (N encontrados)
- ✅ Fase 6: Generando informe...

### Al completar

```
✅ Análisis completado

📊 Resultados — Tokens:
• Consumo actual: X tokens
• Ahorro potencial: Y tokens (Z%)

📊 Resultados — Premium Requests:
• Patrones de aclaración detectados: N
• Tool calls evitables identificadas: N
• Fases fusionables: N

🏆 Quick Wins encontrados: N (tokens: N / premium requests: N / ambos: N)

📄 Informe generado: [ruta]/OPTIMIZATION_REPORT.md

Próximos pasos sugeridos:
1. Revisar el informe completo
2. Priorizar Quick Wins según ROI (tokens + requests)
3. Implementar en rama separada
4. Validar que no se pierde funcionalidad
```

## Casos de Uso

### Uso básico (directorio actual)

```bash
# Usuario ejecuta:
/drupal-optimizer

# O en el chat:
"Analiza esta skill para optimizar tokens"
"Revisa el consumo de esta skill"
"Analiza los premium requests de esta skill"
"¿Cuántas tool calls genera este agente?"
```

### Uso con ruta específica

```bash
# Usuario ejecuta:
/drupal-optimizer path/to/skill

# O en el chat:
"Analiza la skill en agents/drupal-updates"
"Optimiza tokens de .xxx/skills/commit-helper"
```

### Uso para comparación

```bash
# Usuario puede solicitar:
"Analiza ambas skills y compara su eficiencia"
"¿Cuál skill consume más tokens?"
```

## Herramientas y Comandos

### Comandos útiles para el análisis

```bash
# Contar palabras en todos los markdown
find . -name "*.md" -exec wc -w {} + | sort -n

# Encontrar líneas duplicadas entre archivos
for f in *.md; do echo "=== $f ==="; cat "$f"; done | sort | uniq -d

# Buscar bloques de texto repetidos (>5 palabras)
# (requiere herramientas adicionales o análisis manual)

# Calcular tokens totales
find . -name "*.md" -exec wc -w {} + | \
  tail -1 | \
  awk '{printf "Palabras: %d\nTokens estimados: %d\n", $1, int($1*1.33)}'

# Encontrar archivos más grandes
find . -name "*.md" -exec wc -w {} + | sort -rn | head -10
```

## Criterios de Evaluación

### Skill bien optimizada — Tokens

- ✅ Archivo principal <600 tokens
- ✅ Agentes individuales <500 tokens cada uno
- ✅ Sin redundancia >50 tokens
- ✅ Referencias técnicas en archivos separados
- ✅ Formato markdown estándar
- ✅ Carga selectiva de contexto implementada

### Skill bien optimizada — Premium Requests

- ✅ Sin patrones de aclaración forzada ("pregunta al usuario si...")
- ✅ Instrucciones autocontenidas: no requiere leer archivos externos para ejecutarse
- ✅ Condiciones de decisión claras: el agente no necesita confirmar antes de actuar
- ✅ Fases con criterios de salida temprana definidos
- ✅ Subagentes usados solo cuando hay beneficio real de paralelismo
- ✅ Flujo lineal sin bucles innecesarios

### Skill que necesita optimización — Tokens

- ⚠️ Archivo principal >800 tokens
- ⚠️ Agentes desbalanceados (uno 3x más grande que otros)
- ⚠️ Contenido duplicado >100 tokens
- ⚠️ Información de referencia mezclada con instrucciones
- ⚠️ Uso de formatos ineficientes (ASCII art)
- ⚠️ Todo se carga siempre independientemente de la fase

### Skill que necesita optimización — Premium Requests

- ⚠️ Instrucciones con ≥2 patrones de aclaración forzada
- ⚠️ Referencias a ≥3 archivos externos que se cargan en cada ejecución
- ⚠️ Fases secuenciales sin puntos de salida temprana
- ⚠️ Subagentes lanzados sin condición clara de necesidad
- ⚠️ ≥2 fases de verificación redundantes que podrían fusionarse
- ⚠️ Instrucciones ambiguas con términos como "si procede", "si es necesario", "a criterio del agente" sin criterio definido

## Extensiones Futuras

Esta skill puede extenderse para:

1. Análisis comparativo entre múltiples skills
2. Benchmarking contra mejores prácticas
3. Detección automática de patrones anti-pattern
4. Sugerencias de refactoring arquitectónico
5. Integración con CI/CD para validar PRs

---

## Notas Finales

- **Workspace multi-proyecto**: Nunca uses `.` como `TARGET_DIR` sin confirmar antes con la Fase 0 que es el directorio correcto
- Este análisis es una **guía**, no una verdad absoluta
- Prioriza la **claridad** sobre la brevedad extrema
- El objetivo es **eficiencia sin sacrificar funcionalidad**
- Consulta con el equipo antes de cambios estructurales grandes
