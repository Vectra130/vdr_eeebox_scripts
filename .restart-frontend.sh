#!/bin/bash
# v1.4 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#frontend neu starten

. /etc/vectra130/configs/sysconfig/.sysconfig

killall -q -9 .frontend.sh
$SCRIPTDIR/.showscreenimage.sh restart_frontend &
. $SCRIPTDIR/.stopallmultimedia

sed -i -e 's/\(CurrentChannel =\)/\1 1/' $VDRCONFDIR/setup.conf

if [ "$CLIENTTYP" == "eeeBox" ]; then
	$SCRIPTDIR/.reset_hdmi_port.sh
fi

stop autofs

nice -$_watchdog_sh_nice $SCRIPTDIR/.frontend.sh &
killall -q .restart-frontend.sh
sleep 3
exit 0
