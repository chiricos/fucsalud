# Referencia: Integración VRT — drupal-backstop-tests

Guía para `agent-vrt`. Referenciada exclusivamente por: `agent-vrt.md`.

## Prerequisitos

1. Skill `drupal-backstop-tests` disponible en el workspace
2. DDEV add-on `ddev-backstopjs`: `ddev get ddev/ddev-backstopjs`
3. DDEV corriendo: `ddev status` → `running`

Si (1) o (2) faltan → `VRT_DISPONIBLE = false` → saltar stages VRT.

`stage_file_proxy`: recomendado para sincronizar imágenes PROD→LOCAL. Si falta →
WARNING ("imágenes pueden diferir"), NO bloquea. VRT continúa.

## Fases VRT

**Stage 1.5 — Baseline** (tras Stage 1): tipo `menu-pages` por defecto. Resultado:
`vrt-baseline.json`. Gate: opcional (`BASELINE_VRT_OK = N/A` si falla).

**Stage 3.5 — Post-módulos** (tras Stage 3): BackstopJS contra baseline LOCAL (no PROD).
Resultado: `vrt-post-modules.json`. Gate: opcional — bloquear solo si `regressions_new > 0`.

**Stage 9 — Final** (tras Stage 8): comparación definitiva contra baseline. Resultado:
`vrt-final.json`. Gate: opcional — documentar diffs conocidos vs regresiones nuevas.

## Formato JSONs

`vrt-baseline.json`:

```json
{
  "phase": "baseline",
  "timestamp": "ISO-8601",
  "scenarios_count": 12,
  "known_diffs": ["selector1", "selector2"],
  "status": "COMPLETED"
}
```

`vrt-post-modules.json` y `vrt-final.json`:

```json
{
  "phase": "post-modules|final",
  "timestamp": "ISO-8601",
  "compared_against": "baseline",
  "regressions_new": 0,
  "regressions_known": 2,
  "status": "PASS|FAIL"
}
```

## Known Diffs vs Regresiones Nuevas

| Tipo                | Descripción                                        | Acción                                      |
| ------------------- | -------------------------------------------------- | ------------------------------------------- |
| **Known diff**      | Diferencia esperada (contenido dinámico, imágenes) | Aprobar con `ddev backstop approve`         |
| **Regresión nueva** | Diferencia no esperada (layout roto, componente)   | **BLOQUEAR** → PARAR → REPORTAR → PREGUNTAR |

Criterio de bloqueo: solo si `regressions_new > 0`. Known diffs aprobados no bloquean.
