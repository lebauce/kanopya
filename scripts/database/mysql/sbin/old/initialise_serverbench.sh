#!/bin/bash
echo "Loading environment configuration"
. /opt/kanopya/scripts/database/mysql/sbin/env.sh
echo  "DB user is $dbuser"
echo  "DB user is $dbpassword"
echo -n 'Generate database shemas ... '
mysql -u $dbuser -p$dbpassword < /opt/kanopya/scripts/database/mysql/schemas/Schemas.sql
echo 'done'
echo "Load Component DB schemas"
for i in $( cat /opt/kanopya/conf/components.conf ); do
    echo "Installing $i component in db from"
    echo "/opt/kanopya/scripts/database/mysql/schemas/components/$i.sql"
    mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/schemas/components/$i.sql"
done
echo -n 'insert initial data... '
mysql -u $dbuser -p$dbpassword < /opt/kanopya/scripts/database/mysql/data-sample/initialize_for_Bench_server.sql 
echo 'done'
echo '> WARNING ! <'
echo 'LVM logical volumes for default distribution and systemimage must be present to make perl tests'
echo 'You can create them with:'
echo
echo '# lvcreate -L 52M -n etc_Debian_5.0 vg1'
echo '# lvcreate -L 6G -n root_Debian_5.0 vg1'
echo '# lvcreate -L 52M -n etc_DebianSystemImage vg1'
echo '# lvcreate -L 6G -n root_DebianSystemImage vg1'
echo '# lvcreate -L 52M -n etc_ClientBenchSystemImage vg1'
echo '# lvcreate -L 6G -n root_ClientBenchSystemImage vg1'
echo
