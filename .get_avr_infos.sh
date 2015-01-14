#!/bin/bash
# v1.10 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

# Ip, port, relais, hostname der AVR Karte ermitteln

. /etc/vectra130/configs/sysconfig/.sysconfig

logger -t GETAVR "Suche AVR Infos ..."

avrInfo=$(avahi-browse -tlk --resolve --parsable _VDR-Streaming-AVR._tcp | grep ^"=" | sed -e 's/\"//g')

if [ "$(echo $avrInfo | wc -w)" != "0" ]; then
	avrIp=$(echo "$avrInfo" | awk -F';' '{ print $8 }')
	avrPort=$(echo "$avrInfo" | awk -F';' '{ print $9 }')
	avrRelais=$(echo "$avrInfo" | awk -F';' '{ print $10 }')
	avrHostname=$(echo "$avrInfo" | awk -F';' '{ print $7 }' | sed 's/[.]local//g')
#echo "1:" $avrHostname "2:" $avrIp "3:" $avrPort "4:" $avrRelais

        if [[ "$avrIp" != "$AVRIP" || "$avrPort" != "$AVRPORT" || "$avrRelais" != "$AVRRELAIS" || "$avrHostname" != "$AVRHOSTNAME" ]]; then
		sed -i  -e 's/\(AVRIP=\).*/\1\"'$avrIp'\"/' \
			-e 's/\(AVRPORT=\).*/\1\"'$avrPort'\"/' \
			-e 's/\(AVRRELAIS=\).*/\1\"'$avrRelais'\"/' \
			-e 's/\(AVRHOSTNAME=\).*/\1\"'$avrHostname'\"/' \
				$SYSCONFDIR/.sysconfig
		logger -t GETAVR "Aenderungen entdeckt und aktualisiert:"
		logger -t GETAVR "IP -> alt:$AVRIP neu:$avrIp , PORT -> alt:$AVRPORT neu:$avrPort , RELAIS -> alt:$AVRRELAIS neu:$avrRelais , HOSTNAME -> alt:$AVRHOSTNAME neu:avrHostname"
	fi
	sed -i -e 's/\(SERVERWAKEUP\).*/\1=\"AVR\"/' $SYSCONFDIR/.sysconfig
	. $SYSCONFDIR/.sysconfig
else
	#auf die letzte bekannte MAC Adresse des VDR Servers per WOL zurueckgreifen
	echo "VDR-Streaming-AVR wurde nicht gefunden. Setze Wakeup Methode auf WOL"
	logger -t GETAVR "VDR-Streaming-AVR wurde nicht gefunden. Setze Wakeup Methode auf WOL"
	sed -i -e 's/\(SERVERWAKEUP\).*/\1=\"WOL\"/' $SYSCONFDIR/.sysconfig
	. $SYSCONFDIR/.sysconfig
	exit 0
fi
if [[ x$AVRIP == x || x$AVRHOSTNAME == x || x$AVRPORT == x || x$AVRRELAIS == x ]]; then
	exit 2
else
	echo "AVR-Karte '$AVRHOSTNAME' mit der IP '$AVRIP', Port '$AVRPORT' und Relais '$AVRRELAIS' wird verwendet"
	logger -t GETAVR "AVR-Karte '$AVRHOSTNAME' mit der IP '$AVRIP', Port '$AVRPORT' und Relais '$AVRRELAIS' wird verwendet"
	exit 0
fi
