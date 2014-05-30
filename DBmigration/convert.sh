#!/bin/bash
DATEFORM=$(date +"%Y%m%d")
read -p "Where is the 'decc' directory? " STOREDIR
mysqldump decc clients contacts clients_has_contacts billable projects types orders parts batches --compatible=postgresql --skip-add-locks > "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql"
echo 'dumped'

echo 'DROP SCHEMA "tempdecc" CASCADE;
CREATE SCHEMA "tempdecc";
SET search_path = "tempdecc";' | cat - "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql" > temp && mv temp "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql"

sed -e "s,int(11),integer,g" "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql" > temp && mv temp "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql"
grep -v '^  KEY' "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql" > temp && mv temp "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql"

sudo -u postgres psql decc < "$STOREDIR/decc/DBmigration/dumps/deccschema.sql"
sudo -u postgres psql decc < "$STOREDIR/decc/DBmigration/dumps/deccdump$DATEFORM.sql"
sudo -u postgres psql decc < "$STOREDIR/decc/DBmigration/deccmigration.sql"
sudo -u postgres pg_dump decc --data-only > "$STOREDIR/decc/DBmigration/dumps/datadump$DATEFORM.sql"
sudo -u postgres pg_dump decc  > "$STOREDIR/decc/DBmigration/dumps/fullpgdump$DATEFORM.sql"