#!/bin/bash
# v1.15 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#Dieses Script fuert einige Befehle auf dem AVR Board aus

. /etc/vectra130/configs/sysconfig/.sysconfig

if [ "x$AVRIP" == "x" ]; then
	logger -t AVR "AVR Karte nicht gefunden !!!"
	exit 2
fi

AVRHEXPORT=$(echo 'ibase=A;obase=16;(2^('$AVRRELAIS'-1))' | bc)
press_short(){
	#kurzer Druck auf die Power-Taste
		avrCheck=$(echo "io set port 02 "$AVRHEXPORT" "$AVRHEXPORT | socat stdio tcp4-connect:$AVRIP:$AVRPORT)
		sleep 0.5
		avrCheck+=" "$(echo "io set port 02 00 "$AVRHEXPORT | socat stdio tcp4-connect:$AVRIP:$AVRPORT)
}
press_long(){
	#langer Druck auf die Power-Taste
		avrCheck=$(echo "io set port 02 "$AVRHEXPORT" "$AVRHEXPORT | socat stdio tcp4-connect:$AVRIP:$AVRPORT)
                sleep 5
		avrCheck+=" "$(echo "io set port 02 00 "$AVRHEXPORT | socat stdio tcp4-connect:$AVRIP:$AVRPORT)
}

serverStatus="x$(echo 'adc get 0' | socat stdio tcp4-connect:$AVRIP:$AVRPORT)"

case $1 in
	einschalten)
#		if [ x$(expect -c "set echo \"-noecho\"; set timeout 1; spawn -noecho ping -c1 vdrserver.local; expect timeout { exit 1 } eof { exit 0 }" | grep "1 received" | wc -l) != x1 ]; then
#		if [ $(ping -c1 vdrserver.local | grep "1 received" | wc -l) == "0" ]; then
		if [ "$serverStatus" != "x3FF " ]; then
			logger -t AVR "Server einschalten. IP:$AVRIP PORT:$AVRPORT RELAIS:$AVRRELAIS (HEX:$AVRHEXPORT)"
			press_short
			logger -t AVR "$avrCheck"
			echo "$avrCheck"
			SERVERSTATUS="0"
		else
			logger -t AVR "VDR-Server ist bereits eingeschaltet"
			echo "VDR-Server ist bereits eingeschaltet"
			SERVERSTATUS="1"
			exit 1
		fi
	;;

	ausschalten)
#		if [ x$(expect -c "set echo \"-noecho\"; set timeout 1; spawn -noecho ping -c1 vdrserver.local; expect timeout { exit 1 } eof { exit 0 }" | grep "1 received" | wc -l) == x1 ]; then
#		if [ $(ping -c 1 vdrserver.local | grep "1 received" | wc -l) != "0" ]; then
		if [ "$serverStatus" == "x3FF " ]; then
			logger -t AVR "Server runterfahren. IP:$AVRIP PORT:$AVRPORT RELAIS:$AVRRELAIS (HEX:$AVRHEXPORT)"
			press_short
                        logger -t AVR "$avrCheck"
			echo "$avrCheck"
			SERVERSTATUS="1"
                else
                        logger -t AVR "VDR-Server ist bereits ausgeschaltet"
			echo "VDR-Server ist bereits ausgeschaltet"
			SERVERSTATUS="0"
			exit 1
		fi
	;;

	hardreset)
		logger -t AVR "Server HardReset. IP:$AVRIP PORT:$AVRPORT RELAIS:$AVRRELAIS (HEX:$AVRHEXPORT) ServerStatus:$serverStatus"
		press_long
		sleep 5
		press_short
                logger -t AVR "$avrCheck"
		echo "VDR-Server HardReset wird durchgef&uuml;hrt"
	;;

	*)
		echo "Verfuegbare Befehle: einschalten ausschalten hardreset"
	;;
esac

if [ "x${avrCheck:0:2}" == "xOK" ]; then
	exit 0
else
	exit 2
fi
