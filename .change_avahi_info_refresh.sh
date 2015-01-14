#!/bin/bash
# v1.1 all

#nur einmal ausfuehren
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

[ "$SYSTEMTYP" == "SERVER" ] && SYS=Server
[ "$SYSTEMTYP" == "CLIENT" ] && SYS=Client

sleep 5
if [ $(cat $AVAHIDIR/VDR-Streaming-"$SYS".service | grep "<!-- .*CET.* -->" | wc -l) == 0 ]; then
	sed -i -e '4s/.*$/<\!-- '"$(date)"' -->\n&/g' $AVAHIDIR/VDR-Streaming-"$SYS".service
else
	sed -i -e 's/<!-- .*CET.* -->/<!-- '"$(date)"' -->/' $AVAHIDIR/VDR-Streaming-"$SYS".service
fi

touch $AVAHIDIR/VDR-Streaming-"$SYS".service
logger -t AVAHICHANGE "Avahi Services refreshed"

exit 0
