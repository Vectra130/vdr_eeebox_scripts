#!/bin/bash
# v1.2 all

#Update Datei ueberpruefen und ausfuehren

. /etc/vectra130/configs/sysconfig/.sysconfig

start syslog-ng > /dev/null
#mount -o remount,size=400M /tmp > /dev/null

[ "$SYSTEMTYP" == "CLIENT" ] && SYSTEMTYP="$CLIENTTYP"
[ "$SYSTEMTYP" == "SERVER" ] && SYSTEMTYP="Server"
case "$1" in

check)
UPDATEFILE=$(ls /etc/vectra130/update/update_"$SYSTEMTYP"_*.*.*.tar.gz)
if [ ! -e "$UPDATEFILE" ]; then
	logger -t UPDATE "Kein gueltiges Updatefile gefunden!"
	echo "Kein g&uuml;ltiges Update File gefunden!"
	exit 2
fi

logger -t UPDATE "Update File wird entpackt und geprueft"
tar zxpf "$UPDATEFILE" -C /etc/vectra130/update/
OLDVERSION=$(cat /etc/vectra130/VERSION | sed -e 's/\.//g')
NEWVERSION=$(ls /etc/vectra130/update/ | grep -v tar.gz | grep "$(basename $UPDATEFILE .tar.gz)" | awk -F_ '{ print $3 }' | sed -e 's/\.//g')
REQUIREDVERSION=$(cat $(echo $UPDATEFILE | sed 's/.tar.gz//')/update.sh | grep "REQUIREDVERSION=" | sed -e 's/REQUIREDVERSION=//' -e 's/\"//g' -e 's/\.//g')
#REQUIREDVERSION=$(cat /tmp/$(echo $UPDATEFILE | sed 's/.tar.gz//')/update.sh | grep "REQUIREDVERSION=" | sed -e 's/REQUIREDVERSION=//')

echo "Installierte Version: "${OLDVERSION:0:1}"."${OLDVERSION:1:1}"."${OLDVERSION:2}
echo "Update Version &nbsp;&nbsp;&nbsp;&nbsp;: "${NEWVERSION:0:1}"."${NEWVERSION:1:1}"."${NEWVERSION:2}

if [ $[ NEWVERSION-OLDVERSION ] -lt 1 ]; then
	logger -t UPDATE "Updatedatei ist nicht neuer als die aktuelle Version"
	echo "Update File ist nicht neuer als die aktuelle Version"
	rm -r $UPDATEFILE
	exit 2
fi
if [ "$OLDVERSION" != "$REQUIREDVERSION" ]; then
        logger -t UPDATE "Aktuelle Version ist zu alt fuer dieses Update"
	echo "Aktuelle Version ist zu alt f&uuml;r dieses Update. Es wird Version $(cat $(echo $UPDATEFILE | sed 's/.tar.gz//')/update.sh | grep "REQUIREDVERSION=" | sed -e 's/REQUIREDVERSION=//' -e 's/\"//g') ben&ouml;tigt"
        rm -r $UPDATEFILE
        exit 2
fi

echo "Update Gr&ouml;&szlig;e        : "$(du -hs $(echo $UPDATEFILE | sed 's/\.tar.gz//') | awk '{ print $1 }')"B"
logger -t UPDATE "Update kann durchgefuehrt werden"
echo "Update File OK"
exit 0
;;

exec)
logger -t UPDATE "Update wird gestartet"
UPDATEFILE=$(ls /etc/vectra130/update/update_"$SYSTEMTYP"_*.*.*.tar.gz)
bash /etc/vectra130/update/$(basename $UPDATEFILE .tar.gz)/update.sh &
exit 0
;;

esac

exit 0
