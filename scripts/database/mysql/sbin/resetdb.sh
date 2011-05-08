#!/bin/bash
#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

echo 'generating Data.sql... '
perl /opt/kanopya/scripts/database/mysql/sbin/gendatasql.pl
echo 'done'
echo -n 'insert initial data... '
mysql -u $dbuser -p$dbpassword < /opt/kanopya/scripts/database/mysql/data/Data.sql
echo 'done'
echo "Insert component data"
for i in $( cat /opt/kanopya/conf/components.conf ); do
    if [[ -r "/opt/kanopya/scripts/database/mysql/data/components/$i.sql" ]]
    then
	echo "Inserting data for $i component in db from"
	echo "/opt/kanopya/scripts/database/mysql/data/components/$i.sql"
	mysql -u $dbuser -p$dbpassword < "/opt/kanopya/scripts/database/mysql/data/components/$i.sql"
    fi
done
echo 'done'
