#!/bin/bash
echo "Loading environment configuration"
. /opt/kanopya/scripts/database/mysql/sbin/env.sh
echo  "DB user is $dbuser"
echo  "DB user is $dbpassword"

for i in $( cat /opt/kanopya/conf/components.conf ); do
    echo "Installing $i component in db"
    echo " Create tables"
    echo "/opt/kanopya/scripts/database/mysql/schemas/components/$i.sql"
#    mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/schemas/components/$i.sql"
    
    echo "Insert initial values"    
    mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/data-sample/components/$i.sql"
done
echo 'done'
echo
