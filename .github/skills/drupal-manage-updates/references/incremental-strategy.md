# Estrategia de Actualización Incremental

Fuente única de verdad sobre la estrategia incremental.
Referenciada por: `agent-planner.md`, `agent-core-updater.md`.

---

## Principio fundamental

**Siempre actualiza primero a la última versión minor de tu versión mayor actual
antes de saltar a la siguiente versión mayor.**

## Ejemplos de flujo

```
D10.2.5 → D10.6.3 → D11.x   ✅ CORRECTO
D10.2.5 → D11.x              ❌ EVITAR

D9.2.0  → D9.5.11 → D10.x   ✅ CORRECTO
D9.2.0  → D10.x              ❌ EVITAR

D11.0.0 → D11.1.5            ✅ Siempre seguro (mismo major)
```

## Control de saltos — flags para `paso-03`

| Flag            | Comportamiento                                       | Cuándo usar                              |
| --------------- | ---------------------------------------------------- | ---------------------------------------- |
| (sin flag)      | Actualiza a última minor de versión mayor actual     | **Siempre (defecto)**                    |
| `--major-jump`  | Permite salto mayor SOLO si ya estás en última minor | Después de completar actualización minor |
| `--force-major` | Fuerza salto mayor sin estar en última minor         | Solo si el usuario insiste (RIESGO)      |

## Flujo típico D10 → D11

```bash
# 1. Obtener versión objetivo minor
bash scripts/paso-03-version-objetivo.sh
# → Recomendará D10.6.3

# 2. Ejecutar pasos 4-6 hasta MODULES_OK

# 3. Confirmar que estás en última minor
bash scripts/paso-03-version-objetivo.sh
# → ready_for_major_jump: true

# 4. Saltar a D11
bash scripts/paso-03-version-objetivo.sh --major-jump
```

## Ventajas del approach incremental

1. **Menor riesgo** — Las actualizaciones menores tienen menos breaking changes
2. **Testing progresivo** — Validar en cada etapa reduce sorpresas
3. **Bug fixes** — Accedes a todos los patches de seguridad de la última minor
4. **Deprecation warnings** — D10.4+ muestra warnings útiles para preparar D11
5. **Módulos puente optimizados** — Algunos módulos tienen releases para la última minor

## Cómo guiar al usuario

**Si el usuario está en D10.x y pide actualizar a D11:**

1. Informarle del flujo incremental obligatorio
2. Explicar que primero irá a D10.6.x (u última minor disponible)
3. Si insiste en ir directo a D11, usar `--force-major` y advertir del riesgo

**Si el usuario está en D9.x:**

1. Llevar primero a D9.5.11 (última minor de D9)
2. Luego saltar a D10.x con `--major-jump`
3. Opcionalmente continuar a D11.x siguiendo la misma lógica incremental

**Formato para reportar el plan al usuario:**

```
📋 Plan de actualización detectado:
  Versión actual:  D10.2.5
  Versión minor:   D10.6.3 (Paso 1)
  Versión objetivo: D11.x (Paso 2, tras completar Paso 1)

¿Procedo con el Paso 1 (D10.6.3)?
```
