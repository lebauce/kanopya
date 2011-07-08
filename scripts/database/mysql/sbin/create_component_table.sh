#!/bin/bash
echo "Loading environment configuration"
. /opt/kanopya/scripts/database/mysql/sbin/env.sh

component=$1

if [ "$component" = "" ];
then
echo "need parameter: component name and version (ex: comp1)"
exit
fi

echo "Create tables for component $component using:"
echo " /opt/kanopya/scripts/database/mysql/schemas/components/$component.sql"

if mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/schemas/components/$component.sql";
then
echo "done"
echo "Now you must launch MakeSchema.pl <table> for all tables related to your component"
else
echo "=> please manually delete related tables"
fi

echo
