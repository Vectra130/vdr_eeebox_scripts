#!/bin/bash
# v1.12 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

# Ip, hostname und macadresse des VDR-Streaming-Servers ermitteln

. /etc/vectra130/configs/sysconfig/.sysconfig

logger -t GETSERVER "Suche VDR-Server Infos ..."

if [ $(ping -c 1 vdrserver.local | grep "1 received" | wc -l) != "0" ]; then
	serverInfo=$(avahi-browse -tlk --resolve --parsable _VDR-Streaming-Server._tcp | grep ^"=" | sed -e 's/\"//g')
	info=$(echo $serverInfo | awk -F";" '{ print $10 }' | sed /^\s*$/d | tr " " "\n")
	serverIp=$(echo "$serverInfo" | awk -F';' '{ print $8 }')
	serverHostname=$(echo "$serverInfo" | awk -F';' '{ print $7 }' | sed 's/[.]local//g')
	serverMac=$(echo "$info" | grep "MACADRESS=" | awk -F'=' '{ print $2 }')
#echo "2:" $serverIp "3:" $serverHostname "4:" $serverMac

	if [[ "$serverIp" != "$SERVERIP" || "$serverHostname" != "$SERVERHOSTNAME" || "$serverMac" != "$SERVERMAC" ]]; then
		sed -i  -e 's/\(SERVERIP=\).*/\1\"'$serverIp'\"/' \
			-e 's/\(SERVERHOSTNAME=\).*/\1\"'$serverHostname'\"/' \
			-e 's/\(SERVERMAC=\).*/\1\"'$serverMac'\"/' \
				$SYSCONFDIR/.sysconfig
		logger -t GETSERVER "Aenderungen entdeckt und aktualisiert:"
		logger -t GETSERVER "IP -> alt:$SERVERIP neu:$serverIp , HOSTNAME -> alt:$SERVERHOSTNAME neu:$serverHostname , MAC -> alt:$SERVERMAC neu:$serverMac"
	fi
	. $SYSCONFDIR/.sysconfig
fi
if [[ x$SERVERIP == x || x$SERVERHOSTNAME == x || x$SERVERMAC == x ]]; then
	echo "VDR-Streaming-Server wurde nicht gefunden!!!"
	logger -t GETSERVER "VDR-Streaming-Server wurde nicht gefunden!!!"
	exit 2
else
	echo "VDR-Streaming-Server '$SERVERHOSTNAME' mit der IP '$SERVERIP' und der MAC-Adresse '$SERVERMAC' wird verwendet"
	logger -t GETSERVER "VDR-Streaming-Server '$SERVERHOSTNAME' mit der IP '$SERVERIP' und der MAC-Adresse '$SERVERMAC' wird verwendet"
	exit 0
fi
