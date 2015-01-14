#!/bin/bash
# v1.3 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#Kanaele uebers Webinterface bearbeiten

. /etc/vectra130/configs/sysconfig/.sysconfig

chanConf=/root/.vdr/channels.conf
tmpDir=$WWWDIR/config/tmp

case $1 in

read)
# channels.conf kopieren
cp $chanConf $tmpDir
;;

write)
# neue channels.conf kopieren
$SCRIPTDIR/.stop_vdr.sh
cat $tmpDir/channels.conf.new | sed -e '/^\s*$/d' > $chanConf
$SCRIPTDIR/.start_vdr.sh
;;

esac

exit 0
