#!/bin/bash
# v1.0 eeebox

#Nach dem Systemstart wird nach 5min in s2ram gewechselt falls es eingestellt ist

. /etc/vectra130/configs/sysconfig/.sysconfig

[ "$POWEROFF" != "Sleep" ] && exit 0

startTime=$(date +%s)
while true; do
	[ ! -e /tmp/.powersave ] && exit 0
	nowTime=$(date +%s)
	[ $[ nowTime - startTime ] -ge 300 ] && break
	sleep 10
done
touch /tmp/.startsuspend-s3
[ "$(pidof -xs .frontend.sh | wc -w)" == "0" ] && nice -$_watchdog_sh_nice $SCRIPTDIR/.frontend.sh &
exit 0
