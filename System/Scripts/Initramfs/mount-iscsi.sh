#!/bin/bash
##
## mount-iscsi.sh
## 
## Made by Antoine Castaing
## Login   <antoine.castaing@hedera-technology.com>
## 
## Started on  Thu Jul 16 15:32:30 2009 Antoine Castaing
## Last update Thu Jul 16 15:32:30 2009 Antoine Castaing
##

echo "***********************************************************************************************************"
echo "* AUTO ISCSI DETECTION                                                                                    *" 
echo "***********************************************************************************************************"
sleep 3

PARAM=${@}
TARGETIP="10.0.0.1"
TARGETPORT="3260"
DEBUG=1

target_id=( $(iscsiadm -m discovery -t sendtargets -p $TARGETIP:$TARGETPORT | sed 's/.*\(iqn.*\)/\1/') )

for element in $(seq 0 $((${#target_id[@]} - 1)))
  do
  echo "Mounting ${target_id[$element]}"
  echo "iscsiadm -m node -T ${target_id[$element]} -p $TARGETIP -l"
  error=`iscsiadm -m node -T ${target_id[$element]} -p $TARGETIP -l`
  id=`iscsiadm -m session | grep "${target_id[$element]}" | sed 's/.*\[\(.*\)\].*/\1/'` 
  disk=`iscsiadm -m session -P3 -r "$id" | grep "Attached scsi disk" |sed 's/.*\(Attached\ scsi\ disk\).*\(sd.\).*State: running/\2/'`
  disk_iscsi=`echo "${target_id[$element]}" | sed 's/^.*\(\:\)\(.*\)/\2/'`
  echo "le disque est $disk"
  echo "Le disque iscsi est $disk_iscsi"
  mkdir "$disk_iscsi"
  ext=`fsck -N /dev/$disk  | tail -n 1 | sed 's/.*\/sbin\/fsck\.\(.*\)\ .1.\ .*/\1/'`
  echo `fsck -N /dev/$disk`
  echo "ext=$ext"
  echo "mount -t $ext /dev/$disk $disk_iscsi"
  test=`mount -t $ext /dev/$disk $disk_iscsi`
  echo "$test"

#  umount "/dev/$disk $disk"
#  rmdir "$disk_iscsi"
#  error=`iscsiadm -m node -T ${target_id[$element]} -p $TARGETIP --logout`
done