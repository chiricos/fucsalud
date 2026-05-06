#!/usr/bin/env bash
# =============================================================================
# cleanup-snapshots.sh -- Limpia snapshots DDEV antiguos
#
# Resuelve bug #7: acumulacion de snapshots que ocupan espacio en disco.
#
# Uso:
#   bash scripts/cleanup-snapshots.sh           # Conservar ultimos 3 (default)
#   bash scripts/cleanup-snapshots.sh --keep 5  # Conservar ultimos 5
#   bash scripts/cleanup-snapshots.sh --list    # Listar snapshots sin eliminar
#   bash scripts/cleanup-snapshots.sh --dry-run # Ver que se eliminaria
# =============================================================================

set -uo pipefail

KEEP=3
LIST_ONLY="false"
DRY_RUN="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --keep)
            KEEP="${2:?'--keep requiere un numero'}"
            shift
            ;;
        --list)
            LIST_ONLY="true"
            ;;
        --dry-run)
            DRY_RUN="true"
            ;;
        --help|-h)
            echo "Uso:"
            echo "  cleanup-snapshots.sh              Conservar ultimos 3 snapshots"
            echo "  cleanup-snapshots.sh --keep N     Conservar ultimos N snapshots"
            echo "  cleanup-snapshots.sh --list       Listar snapshots sin eliminar"
            echo "  cleanup-snapshots.sh --dry-run    Ver que se eliminaria"
            exit 0
            ;;
        *)
            echo "  Warning: Argumento no reconocido: $1"
            ;;
    esac
    shift
done

if ! ddev describe > /dev/null 2>&1; then
    echo "  Stopped: DDEV no esta activo"
    exit 1
fi

PROJECT_NAME=$(ddev describe -j 2>/dev/null | jq -r '.raw.name' 2>/dev/null || echo "")
if [ -z "$PROJECT_NAME" ]; then
    echo "  Error: No se pudo obtener el nombre del proyecto DDEV"
    exit 1
fi

# Ubicacion de snapshots DDEV
SNAPSHOT_DIR="$HOME/.ddev/snapshots/$PROJECT_NAME"
if [ ! -d "$SNAPSHOT_DIR" ]; then
    # Intentar path alternativo
    SNAPSHOT_DIR="$(pwd)/.ddev/db_snapshots"
fi

echo ""
echo "  Snapshots DDEV — Proyecto: $PROJECT_NAME"
echo "  Directorio: $SNAPSHOT_DIR"
echo ""

if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "  Sin snapshots: directorio no encontrado."
    exit 0
fi

# Listar snapshots ordenados por fecha (mas nuevo ultimo)
# shellcheck disable=SC2012
SNAPSHOTS=()
while IFS= read -r _snap; do SNAPSHOTS+=("$_snap"); done < <(ls -t "$SNAPSHOT_DIR" 2>/dev/null || true)
TOTAL=${#SNAPSHOTS[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "  Sin snapshots registrados."
    exit 0
fi

echo "  Total de snapshots: $TOTAL"
echo "  Conservar: $KEEP"
echo ""

# Listar todos
echo "  ID  Nombre                                   Tamano"
echo "  --- ---------------------------------------- ----------"
IDX=1
for SNAP in "${SNAPSHOTS[@]}"; do
    SIZE=$(du -sh "$SNAPSHOT_DIR/$SNAP" 2>/dev/null | awk '{print $1}' || echo "?")
    MARKER=""
    [ "$IDX" -le "$KEEP" ] && MARKER=" (mantener)"
    printf "  %-3d %-40s %-10s%s\n" "$IDX" "$SNAP" "$SIZE" "$MARKER"
    IDX=$((IDX + 1))
done

if [ "$LIST_ONLY" = "true" ]; then
    echo ""
    echo "  Modo --list: no se elimina nada."
    exit 0
fi

if [ "$TOTAL" -le "$KEEP" ]; then
    echo ""
    echo "  Nada que limpiar: hay $TOTAL snapshots, limite es $KEEP."
    exit 0
fi

TO_DELETE=$(( TOTAL - KEEP ))
echo ""
echo "  Eliminar: $TO_DELETE snapshot(s) mas antiguos"
echo ""

DELETED=0
FREED=0
IDX=1
for SNAP in "${SNAPSHOTS[@]}"; do
    if [ "$IDX" -gt "$KEEP" ]; then
        SNAP_PATH="$SNAPSHOT_DIR/$SNAP"
        SIZE_KB=$(du -sk "$SNAP_PATH" 2>/dev/null | awk '{print $1}' || echo "0")
        if [ "$DRY_RUN" = "true" ]; then
            echo "  (dry-run) Eliminaria: $SNAP  (${SIZE_KB}KB)"
        else
            echo "  Eliminando: $SNAP"
            rm -rf "$SNAP_PATH"
            DELETED=$((DELETED + 1))
            FREED=$((FREED + SIZE_KB))
        fi
    fi
    IDX=$((IDX + 1))
done

echo ""
if [ "$DRY_RUN" = "true" ]; then
    echo "  Dry-run completado. Usa sin --dry-run para eliminar."
else
    FREED_MB=$(( FREED / 1024 ))
    echo "  Eliminados: $DELETED snapshot(s)"
    echo "  Espacio liberado: ~${FREED_MB}MB"
    echo "  Snapshots restantes: $KEEP"
fi
