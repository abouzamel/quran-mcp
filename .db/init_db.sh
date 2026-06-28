#!/bin/bash
# Initialise the quran_mcp database on first postgres start.
# Runs automatically via docker-entrypoint-initdb.d/ when the volume is fresh.
#
# Migrations ALWAYS run so the schema (quran_com + quran_mcp) is fully built,
# even with no dump present. Dump loading is optional and skipped gracefully
# if the dump files are missing (server works without corpus data; tools
# return empty results until data is seeded).

set -e

DUMP="/docker-entrypoint-initdb.d/dumps/quran_com_data_only_20260624_001103.sql.gz"
MIGRATIONS_DIR="/docker-entrypoint-initdb.d/migrations"

# ---------------------------------------------------------------------------
# 1. Apply ALL migrations in order (ALWAYS — independent of dumps).
#    Records each in schema_migration so the app's run_migrations() skips them.
# ---------------------------------------------------------------------------
echo "init_db: Applying all migrations ..."
for sql in $(ls "$MIGRATIONS_DIR"/*.sql | sort); do
    version=$(basename "$sql" | grep -o '^[0-9]*' | sed 's/^0*//')
    [ -z "$version" ] && version=0
    echo "init_db:   $(basename "$sql")"
    # Strip pg_dump artifacts that break psql -f:
    #   - \restrict / \unrestrict meta-commands (newer pg_dump)
    #   - make CREATE SCHEMA idempotent (01-init.sql already made quran_mcp)
    sed -E \
        -e '/^\\(un)?restrict /d' \
        -e 's/^CREATE SCHEMA ([a-z_]+);/CREATE SCHEMA IF NOT EXISTS \1;/' \
        "$sql" \
    | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" --quiet -f -
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --quiet -c \
        "INSERT INTO quran_mcp.schema_migration (version) VALUES ($version) ON CONFLICT DO NOTHING;"
done
echo "init_db: Migrations applied — schema is ready."
# ---------------------------------------------------------------------------
# 2. Optional corpus data load (skipped gracefully when no dump present).
# ---------------------------------------------------------------------------
if [ ! -f "$DUMP" ]; then
    echo "init_db: $DUMP not found — skipping corpus data load (schema-only start)."
    echo "init_db: The server will start; tools return empty results until seeded."
    exit 0
fi

echo "init_db: Loading corpus data from $DUMP ..."
gunzip -c "$DUMP" | psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --quiet 2>&1 | grep -v "^ERROR" || true
echo "init_db: Done loading corpus data."

# Edition content dump (optional).
EDITION_FULL="/docker-entrypoint-initdb.d/dumps/quran_mcp_data_only_20260624_001031.sql.gz"
EDITION_PARTIAL="/docker-entrypoint-initdb.d/dumps/quran_mcp_edition_content.partial.sql.gz"

if [ -f "$EDITION_FULL" ]; then
    echo "init_db: Loading edition content from $EDITION_FULL ..."
    gunzip -c "$EDITION_FULL" | psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --quiet 2>&1 | grep -v "^ERROR" || true
    echo "init_db: Done loading edition content (full)."
elif [ -f "$EDITION_PARTIAL" ]; then
    echo "init_db: Loading edition content from $EDITION_PARTIAL ..."
    gunzip -c "$EDITION_PARTIAL" | psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --quiet 2>&1 | grep -v "^ERROR" || true
    echo "init_db: Done loading edition content (partial)."
else
    echo "init_db: No edition content dump found — skipping."
fi

# # --- GoodMem qwen seed (loads into goodmem_qwen_db) ---
# GM_QWEN_DB="goodmem_qwen_db"
# GOODMEM_QWEN_FULL="/docker-entrypoint-initdb.d/dumps/goodmem_qwen_full_20260623_094812.sql.gz"

# if [ -f "$GOODMEM_QWEN_FULL" ]; then
#     echo "init_db: Loading goodmem qwen content from $GOODMEM_QWEN_FULL into $GM_QWEN_DB ..."
#     gunzip -c "$GOODMEM_QWEN_FULL" | psql -U "$POSTGRES_USER" -d "$GM_QWEN_DB" --quiet 2>&1 | grep -v "^ERROR" || true
#     echo "init_db: Done loading goodmem qwen content (full)."
# else
#     echo "init_db: No goodmem qwen content dump found — skipping."
# fi

# # --- GoodMem openai seed (loads into goodmem_openai_db) ---
# GM_OPENAI_DB="goodmem_openai_db"
# GOODMEM_OPENAI_FULL="/docker-entrypoint-initdb.d/dumps/goodmem_openai_full_20260622_114740.sql.gz"

# if [ -f "$GOODMEM_OPENAI_FULL" ]; then
#     echo "init_db: Loading goodmem openai content from $GOODMEM_OPENAI_FULL into $GM_OPENAI_DB ..."
#     gunzip -c "$GOODMEM_OPENAI_FULL" | psql -U "$POSTGRES_USER" -d "$GM_OPENAI_DB" --quiet 2>&1 | grep -v "^ERROR" || true
#     echo "init_db: Done loading goodmem openai content (full)."
# else
#     echo "init_db: No goodmem openai content dump found — skipping."
# fi