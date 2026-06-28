#!/bin/bash
# Creates the separated GoodMem database (goodmem_qwen_db) on first postgres start.
# Must run BEFORE 02-init-db.sh, which loads the GoodMem dump into it.
# Mount as 00-init-goodmem-db.sh so it sorts first in docker-entrypoint-initdb.d/.
# The role $POSTGRES_USER already exists at this point (created by POSTGRES_USER env).

set -euo pipefail

GM_DB="${GM_POSTGRES_DB:-goodmem_qwen_db}"

echo "init_goodmem_db: Ensuring database '$GM_DB' exists (owner $POSTGRES_USER) ..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE $GM_DB OWNER $POSTGRES_USER'
    WHERE NOT EXISTS (
        SELECT FROM pg_database WHERE datname = '$GM_DB'
    )\gexec
EOSQL

echo "init_goodmem_db: Done."
