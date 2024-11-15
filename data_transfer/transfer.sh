#!/bin/bash

set -e


EXTERNAL_DB_HOST=${EXTERNAL_DB_HOST}
EXTERNAL_DB_PORT=${EXTERNAL_DB_PORT}
EXTERNAL_DB_USER=${EXTERNAL_DB_USER}
EXTERNAL_DB_PASSWORD=${EXTERNAL_DB_PASSWORD}
EXTERNAL_DB_NAME=${EXTERNAL_DB_NAME}

EXPORT_DIR="/usr/app/dbt/seeds/raw_data"
mkdir -p "$EXPORT_DIR"

declare -A TABLES
TABLES=(
  ["raw_github"]="issues"
  ["raw_finance"]="invoice"
)

export_table_to_csv() {
  local schema=$1
  local table=$2
  local table_file="${EXPORT_DIR}/${schema}_${table}.csv"

  export PGPASSWORD=$EXTERNAL_DB_PASSWORD

  echo "Exporting data for $schema.$table to $table_file..."

  psql -h $EXTERNAL_DB_HOST -p $EXTERNAL_DB_PORT -U $EXTERNAL_DB_USER -d $EXTERNAL_DB_NAME -c \
    "\copy $schema.$table TO '$table_file' CSV HEADER"

  echo "Data exported for $schema.$table successfully."
}

echo "Starting export process..."
for schema in "${!TABLES[@]}"; do
  for table in ${TABLES[$schema]}; do
    table_file="${EXPORT_DIR}/${schema}_${table}.csv"

    if [ -f "$table_file" ]; then
      echo "Data for $schema.$table already exists, skipping export."
    else
      export_table_to_csv "$schema" "$table"
    fi
  done
done

echo "Data export process completed successfully."

touch /data/transfer_done
