#!/bin/bash
# v1.4 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

$SCRIPTDIR/.get_wol_mac_adresses.sh

addrPath=$USERCONFDIR

if [[ ! -e $addrPath/wol-adressen || "$cat $addrPath/wol-adressen | wc -w)" == "0" ]]; then
	echo -e "\nConfig Datei '$addrPath/wol-adressen' nicht vorhanden oder leer !!!\n"
	exit 0
fi

aufwecken(){
wolAddr=$(cat $addrPath/wol-adressen | grep $1 | awk '{ print $2 }')
wolIp=$(cat $addrPath/wol-adressen | grep $1 | awk '{ print $3 }')
echo -e "\e[34m\nVersuche Maschine mit dem Hostname '$1' und der MAC-Adresse '$wolAddr' aufzuwecken ...\n\e[0m"
wakeonlan $wolAddr

if [ "$wolIp" == "AVAHI" ]; then
	time=0
	while [ $time -le 30 ]; do
		if [ "$(avahi-browse -ltk _workstation._tcp | grep -i $wolAddr | wc -l)" != "0" ]; then
			echo "Maschine '$1' wurde erfolgreich nach $time Sekunden aufgeweckt"
			exit 0
		fi
		sleep 1
		time=$[ time + 1 ]
	done
	echo "Maschine '$1' antwortet nach 30 Sekunden nicht. Aufwecken fehlgeschlagen?"
	wolIp=""
fi

if [ "$wolIp" != "" ]; then
	time=0
	while [ $time -gt 30 ]; do
		if [ "$(ping -q -c1 $wolIp | grep '100% packet loss' | wc -l)" == "0" ]; then
			echo "Maschine '$1' wurde erfolgreich nach $time Sekunden aufgeweckt"
			exit 0
		fi
		sleep 1
		time=$[ time + 1 ]
	done
	echo "Maschine '$1' antwortet nach 30 Sekunden nicht. Aufwecken fehlgeschlagen?"
	wolIp=""
fi
exit 0
}

info(){
cat $addrPath/wol-adressen
echo -e "\n\n"
exit 0
}


case $1 in

"")
	echo -e "Nutzung: wol-aufwecken.sh [Hostname]\n"
	info
	exit 0
	;;
*)
	if [ "$(cat $addrPath/wol-adressen | grep -w $1 | awk '{ print $1 }' | wc -w)" == "1" ]; then
		aufwecken $1
		exit 0
	else
		echo -e "Nutzung: wol-aufwecken.sh [Hostname]\n"
		info
		exit 0
	fi
	;;
esac
exit 0
