#!/bin/sh

DEBUG=4

# Configure Network
. /conf/initramfs.conf
for conf in conf/conf.d/*; do
    [ -f ${conf} ] && . ${conf}
done
. /scripts/functions
configure_networking

if [ "$DEBUG" -ge "4" ]
then
    cat /tmp/net-"${DEVICE}".conf 
fi

# Get hostname
HOSTNAME=`hostname`

if [ ! -e /tmp/net-"${DEVICE}".conf ] 
    then
    echo "No network configured"
    exit 155
fi


for x in $(cat /tmp/net-"${DEVICE}".conf); do
    case ${x} in
        ROOTSERVER=*) 
        if [ "$DEBUG" -ge "4" ]
        then
            echo "${x}"
        fi
        TFTPSERVER="${x#ROOTSERVER=}"
        ;;
    esac
done

cd /tmp
echo "Getting $HOSTNAME.conf..."
tftp -g -r "$HOSTNAME".conf "$TFTPSERVER"


