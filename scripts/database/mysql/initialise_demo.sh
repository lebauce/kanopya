#!/bin/bash
password=Hedera@123
echo -n 'recreate database shema... '
mysql -u root -p$password < /workspace/mcs/Administrator/Conf/Schemas.sql
echo 'done'
echo -n 'insert initial data... '
mysql -u root -p$password < /workspace/mcs/Administrator/Conf/Demo.sql 
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
