#!/bin/bash
# v1.0 eeebox

#Watchdog der nach 10 Sekunden den s2ram Dienst killt, falls der sich beim suspend abschiesst

START=$(date +%s)
sleep 5
if [ $(date +%s) == $[ START + 5 ] ]; then
	logger -t S2RAM "s2ram hängt ... beende Dienst"
	killall -q s2ram
fi
exit 0
