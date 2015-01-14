#!/bin/bash
# v2.9 all clients

. /etc/vectra130/configs/sysconfig/.sysconfig

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0


logger -t SERVERWAKEUP "Suche Streaming-Server ..."


vdrOnlineCheck() {
if [ $(nmap -p 2004 $SERVERIP | grep ^2004/ | grep -w open | wc -l) != 0 ]; then
	logger -t SERVERWAKEUP "vdrOnlineCheck 1"
	return 1
else
	logger -t SERVERWAKEUP "vdrOnlineCheck 0"
	return 0
fi
}

serverOnlineCheck() {
power=$(expect -c "set echo \"-noecho\"; set timeout 1; spawn -noecho ping -c1 $SERVERIP; expect timeout { exit 1 } eof { exit 0 }" | grep "1 received" | wc -l)
#power=$(echo "adc get 0" | socat stdio tcp4-connect:$AVRIP:$AVRPORT)
if [ x$power == x1 ]; then
#if [ x$power == x3FF ]; then
	logger -t SERVERWAKEUP "serverOnlineCheck 1"
	return 1
else
	logger -t SERVERWAKEUP "serverOnlineCheck 0"
	return 0
fi
}

vdrIsOnline() {
logger -t SERVERWAKEUP "Streamdev-Server ist bereit"
serverWakeUpOk
}

serverIsOnline() {
logger -t SERVERWAKEUP "Streaming-Server ($SERVERIP) ist Online"
if [ ! -e /tmp/.startvdr ]; then
	# EntertainmentCenter braucht keinen VDR Server
	logger -t SERVERWAKEUP "EntertainmentCenter benoetigt keinen Start des Streamdev-Servers. Breche weitere Suche ab."
	serverWakeUpOk
	exit 0
fi
}

serverWakeUp() {
if [ "$SERVERWAKEUP" == "AVR" ]; then
	logger -t SERVERWAKEUP "Wecke Streaming-Server mit AVR-Methode auf"
	serverWakeUpAvr
else
	logger -t SERVERWAKEUP "Wecke Streaming-Server mit WOL-Methode auf"
	serverWakeUpWol
fi
}

serverWakeUpAvr() {
$SCRIPTDIR/.vdrserver_avr_commands.sh einschalten
if [ x$? == x2 ]; then
	logger -t SERVERWAKEUP "Einschalten mit AVR-Karte nicht erfolgreich! Wecke Streaming-Server mit WOL-Methode auf"
	serverWakeUpWol
fi
}

serverWakeUpWol() {
if [ "$SERVERMAC" != "" ]; then
	wakeonlan $SERVERMAC
else
	serverWakeUpFailed
fi
}

serverWakeUpOk() {
logger -t SERVERWAKEUP "Streaming-Server ist bereit"
setImage blank
ls /nfs/vdrserver/ > /dev/null &
unsetAvahiInfo
exit 0
}

serverWakeUpFailed() {
logger -t SERVERWAKEUP "Das aufwecken des Streaming-Servers war nicht erfolgreich!!!"
setImage vdrserverfail
unsetAvahiInfo
sleep 5
exit 2
}

serverHardReset() {
logger -t SERVERWAKEUP "Versuche einen Hardreset des Streaming-Servers!!!"
setImage vdrserverhardreset
$SCRIPTDIR/.vdrserver_avr_commands.sh hardreset
if [ x$? == x2 ]; then
	logger -t SERVERWAKEUP "Hardreset mit AVR-Karte nicht erfolgreich!"
	serverWakeUpFailed
fi
}

setAvahiInfo() {
#Den anderen Clients mitteilen das ich den Server suche
logger -t SERVERWAKEUP "Setze Avahi Info"
$SCRIPTDIR/.change_avahi_info.sh startserver 1
}

unsetAvahiInfo() {
#Den anderen Clients mitteilen das ich den Server nicht mehr suche
logger -t SERVERWAKEUP "Setze Avahi Info zurueck"
$SCRIPTDIR/.change_avahi_info.sh startserver 0
}

checkAvahiWakeUp() {
#Pruefen ob schon ein Client versucht den VDRServer aufzuwecken
info=""
while [ $(avahi-browse -tlk --resolve --parsable _VDR-Streaming-Client._tcp | grep ^"=" | sed -e 's/\"//g' | grep "startserver=1" | wc -l) != 0 ]; do
	[ x$info == x ] && logger -t SERVERWAKEUP "Ein anderer Client versucht den VDRServer aufzuwecken. Warte bis der Vorgang beendet ist ..."
	[ x$info == x300 ] && exit 0
	info=$[ info + 1 ]
	sleep 1
done
}

setImage() {
killall -9 -q .showscreenimage.sh
$SCRIPTDIR/.showscreenimage.sh $1 &
}


###### Streaming-Server Check ######

#Vorsorglich den aufweck Befehl geben
serverWakeUpAvr

#Pruefen ob Streaming-Server laeuft
serverOnlineCheck
if [ x$? == x1 ]; then
	vdrOnlineCheck
	[ x$? == x1 ] && vdrIsOnline
fi

#Wenn Streaming-Server nicht laeuft
setImage vdrserverwakeup
setAvahiInfo

#serverWakeUp
while true; do
	#Server Status
	logger -t SERVERWAKEUP "Warte 60 Sekunden auf Ping des Streaming-Servers"
	serverStartTime=$(date +%s)
	while [ $(( $(date +%s)-$serverStartTime )) -le 60 ]; do
		serverOnlineCheck
		[ x$? == x1 ] && serverStatus=1 && break
		if [ $(( $(date +%s)-$serverStartTime )) == 10 ]; then
			serverWakeUpAvr
		fi
		sleep 0.5
	done
	if [ x$serverStatus == x1 ]; then
		serverIsOnline
		while true; do
			#VDR Status
			setImage vdrserverstart
			logger -t SERVERWAKEUP "Warte 30 Sekunden auf Start des Streamdev-Servers"
			vdrStartTime=$(date +%s)
			while [ $(( $(date +%s)-$vdrStartTime )) -le 30 ]; do
				vdrOnlineCheck
				[ x$? == x1 ] && vdrStatus=1 && vdrIsOnline
				sleep 0.5
			done
			[ x$vdrCount == x1 ] && break
			logger -t SERVERWAKEUP "VDR-Server antwortet nicht, starte VDR neu"
			touch /nfs/vdrserver/.vdr_restart
			vdrCount=1
		done
	fi
	[ x$serverCount == x1 ] && serverWakeUpFailed
	serverHardReset
	serverCount=1
	sleep 10
	setImage vdrserverwakeup
done

exit 0
