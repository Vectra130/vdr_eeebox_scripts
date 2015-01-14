#!/bin/bash
# v1.0 all clients

#VDR Aufnahmen in Liste ein und austragen

CONVERTFILE=/nfs/vdrserver/.convert_vdr_recordings

case $1 in

 add)
	echo "$2" >> $CONVERTFILE
 ;;
 remove)
	sed -i '/'"$1"'/d' $CONVERTFILE
 ;;

esac
sleep 5
exit 0
