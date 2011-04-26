#!/bin/bash
echo "Loading environment configuration"
. /opt/kanopya/scripts/database/mysql/sbin/env.sh
echo  "DB user is $dbuser"
echo  "DB user is $dbpassword"
echo -n 'Generate database shemas ... '
mysql -u $dbuser -p$dbpassword < /opt/kanopya/scripts/database/mysql/schemas/Schemas.sql
echo 'done'
echo "Load Component DB schemas"
for i in $( cat /etc/kanopya/components.conf ); do
    echo "Installing $i component in db from"
    echo "/opt/kanopya/scripts/database/mysql/schemas/components/$i.sql"
    mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/schemas/components/$i.sql"
done

echo 'generating Data.sql... '
perl /opt/kanopya/scripts/database/mysql/sbin/gendatasql.pl
echo 'done'
echo -n 'insert initial data... '
mysql -u $dbuser -p$dbpassword < /opt/kanopya/scripts/database/mysql/data/Data.sql
echo 'done'
echo "Insert component data"
for i in $( cat /etc/kanopya/components.conf ); do
    if [[ -r "/opt/kanopya/scripts/database/mysql/data/components/$i.sql" ]]
    then
	echo "Inserting data for $i component in db from"
	echo "/opt/kanopya/scripts/database/mysql/data/components/$i.sql"
	mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/data/components/$i.sql"
    fi
done
echo 'done'
