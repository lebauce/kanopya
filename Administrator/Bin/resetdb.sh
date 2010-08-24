#!/bin/bash
password=Hedera@123
echo -n 'recreate database shema...'
mysql -u root -p$password < /workspace/mcs/Administrator/Conf/Schemas.sql
echo 'done'
echo -n 'insert initial data...'
mysql -u root -p$password < /workspace/mcs/Administrator/Conf/Data.sql
echo 'done'