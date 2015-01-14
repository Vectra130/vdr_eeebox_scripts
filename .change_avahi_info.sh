#!/bin/bash
# v1.4 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

# avahi Info setzen

. /etc/vectra130/configs/sysconfig/.sysconfig

[ "$SYSTEMTYP" == "SERVER" ] && SYS=Server
[ "$SYSTEMTYP" == "CLIENT" ] && SYS=Client

if [ $(cat $AVAHIDIR/VDR-Streaming-"$SYS".service | grep ">"$1"=.*<" | wc -l) == 0 ]; then
	#neuen Wert anlegen
	TMP=$(cat /etc/avahi/services/VDR-Streaming-"$SYS".service | head -$(($(cat /etc/avahi/services/VDR-Streaming-"$SYS".service | wc -l)-2)))
	TMP+="\n    <txt-record>"$1"="$2"</txt-record>"
	TMP+="\n"
	TMP+=$(cat /etc/avahi/services/VDR-Streaming-"$SYS".service | tail -2)
	echo -e "$TMP" > $AVAHIDIR/VDR-Streaming-"$SYS".service
	logger -t AVAHICHANGE "Neuen Wert '$1=$2' angelegt"
	$SCRIPTDIR/.change_avahi_info_refresh.sh &
else
	if [ $(cat $AVAHIDIR/VDR-Streaming-"$SYS".service | grep ">"$1"="$2"<" | wc -l) == 0 ]; then
		sed -i -e 's/>'$1'=.*</>'$1'='$2'</' $AVAHIDIR/VDR-Streaming-"$SYS".service
		logger -t AVAHICHANGE "Wert '$1' auf $2 geaendert"
		$SCRIPTDIR/.change_avahi_info_refresh.sh &
	fi
fi

exit 0
