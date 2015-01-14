#!/bin/bash
# v1.0 test

#Wenn innerhalb von 1 Sekunde die Taste nicht nochmal gedrueckt wird, wird irexec restartet um den counter wieder auf null zu setzen

. /etc/vectra130/configs/sysconfig/.sysconfig

sleep 0.2
killall -9 -q irexec && irexec $SYSCONFDIR/.irexec.conf &
exit 0
