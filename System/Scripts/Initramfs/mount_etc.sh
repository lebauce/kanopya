#!/bin/sh

# mount /tmp/etc previously detared in tmpfs

HOSTNAME=`hostname`

echo ""
echo "------------------> Mounting /etc tmpfs : $HOSTNAME <-------------------------"

#mount -t tmpfs tmpfs ${rootmnt}/etc

mount
sleep 5




#echo "Untar /tmp/""$HOSTNAME""_etc.tar in /etc"
#tar xvvf /tmp/"$HOSTNAME"_etc.tar -C ${rootmnt}/etc 


