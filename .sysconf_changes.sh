#!/bin/bash
# v1.11 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#Skript wird nach Aenderungen an .config ausgefuehrt und aendert die noetigen Parameter

set_avahi() {
#avahi service eintrag
cat > /etc/avahi/services/video_hdd_mount_${1}.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
<name replace-wildcards="yes">/vdrvideo0$1|$2|nfstype=$3|/$4</name>
<service>
       <type>_VDR-Streaming-Mount._tcp</type>
</service>
</service-group>
EOF
}

#sysconfig aktualisieren
/etc/vectra130/scripts/.create_sysconfig.sh
. /etc/vectra130/configs/sysconfig/.sysconfig

REBOOT=0
VDRRESTART=0

#ANFANG --- Aenderungen die einen Neustart benoetigen
FOUND=0
CONFIGNOW=$(cat /etc/network/interfaces | grep -v "\ lo\ ")


grep_network_info(){
#logger -t TMP "$FOUND-$TMP-"
	TMP=$(echo "$CONFIGNOW" | grep $TMP | awk '{ print $2 }' | sed -e 's/\"//g')
#logger -t TMP2 "-$TMP-"
}

found_reboot_modification(){
SUBIP=$(echo $IP | awk -v FS="." '{ print $1 "." $2 "." $3 }')
#/etc/network/interfaces erstellen
[ "$USEDHCP" == "1" ] && TYP="dhcp" \
			|| TYP="static"
[ "$USEWLAN" == "1" ] && INTERFACE="wlan0" \
			|| INTERFACE="eth0"
cat > /etc/network/interfaces <<EOF
# ACHTUNG!!! Nicht bearbeiten! Wird automatisch vom
# sysconf_changes Skript generiert

auto lo
iface lo inet loopback

allow-hotplug $INTERFACE
iface $INTERFACE inet $TYP
EOF
if [ "$USEDHCP" != "1" ]; then
cat >> /etc/network/interfaces <<EOF
        address $IP
        netmask $NETMASK
        network $SUBIP.0
        broadcast $SUBIP.255
        gateway $GATEWAY
EOF
fi

if [[ "$USEWLAN" == "1" && "$SYSTEMTYP" == "CLIENT" ]]; then # client only
cat >> /etc/network/interfaces <<EOF
        wpa-ap-scan 1
        wpa-ssid "$WLANSSID"
        wpa-psk "$WPAKEY"
EOF
fi

#/etc/hostname erstellen
echo $HOSTNAME > /etc/hostname

#kodi Devicename setzen
if [ "$SYSTEMTYP" == "CLIENT" ]; then # client only
	sed -i -e 's/devicename.*\/devicename/devicename\>'$HOSTNAME'\<\/devicename/g' $KODICONFDIR/userdata/advancedsettings.xml
fi

#/etc/samba/smb.conf aendern
	sed -i -e 's/\(workgroup =\).*/\1 '$WORKGROUP'/' /etc/samba/smb.conf
	sed -i -e 's/\(netbios name =\).*/\1 '$HOSTNAME'/' /etc/samba/smb.conf

#/etc/mailname erstellen
echo $HOSTNAME > /etc/mailname

#/etc/hosts aendern
echo -e "127.0.1.1\t\t"$HOSTNAME > /etc/hosts
echo -e $SERVERIP"\t\t"$SERVERHOSTNAME >> /etc/hosts

#/etc/resolv.conf aendern
sed -i -e 's/nameserver.*/nameserver '$NAMESERVER'/' /etc/resolv.conf

REBOOT=1
}


#Typ pruefen
TMP=$(echo "$CONFIGNOW" | grep "iface" | awk '{ print $4 }')
[ "$TMP" == "dhcp" ] && TMP="1" \
		     || TMP="0"
[ "$USEDHCP" != "$TMP" ] && FOUND=2

if [ "$USEDHCP" == "0" ]; then
	#IP pruefen
	TMP="address"
	grep_network_info
	[ "$TMP" != "$IP" ] && FOUND=3

	#Gateway pruefen
	TMP="gateway"
	grep_network_info
	[ "$TMP" != "$GATEWAY" ] && FOUND=4

	#Netmask pruefen
	TMP="netmask"
	grep_network_info
	[ "$TMP" != "$NETMASK" ] && FOUND=5
fi

#Wlan spezifische Tests
if [[ "$USEWLAN" == "1" && "$SYSTEMTYP" == "CLIENT" ]]; then # client only
	TMP="wpa-ssid"
	grep_network_info
	[ "$TMP" != "$WLANSSID" ] && FOUND=6

	TMP="wpa-psk"
	grep_network_info
	[ "$TMP" != "$WPAKEY" ] && FOUND=7
fi

#Hostnamen pruefen
[ "$(cat /etc/hostname)" != "$HOSTNAME" ] && FOUND=8

#Nameserver pruefen
[ "$(cat /etc/resolv.conf | grep nameserver)" != "nameserver $NAMESERVER" ] && FOUND=8

#Arbeitsgruppe pruefen
#if [ "$SYSTEMTYP" == "SERVER" ]; then # server only
	[ "$(cat /etc/samba/smb.conf | grep 'workgroup =' | awk '{ print $3 }')" != "$WORKGROUP" ] && FOUND=9
#fi

#Lizenzen pruefen
if [[ "$SYSTEMTYP" == "CLIENT" && "$CLIENTTYP" == "RasPi" ]]; then # raspi only
	$SCRIPTDIR/.checklicense.sh

	#Debug Modus pruefen
	if [ "$(cat /boot/cmdline.txt | sed 's/.*\(console=tty[0-9]*\) .*/\1/g')" != "console=tty$CONSOLE" ]; then
		mount -o rw,remount /boot
		cat /boot/cmdline.txt | sed -e 's/\(console=tty\)[0-9]* /\1'$CONSOLE' /' > /boot/cmdline.txt.bkp && cp /boot/cmdline.txt.bkp /boot/cmdline.txt
		mount -o ro,remount /boot
		REBOOT=2
	fi

fi


#Aenderung gefunden die Neustart erfordert?
[ "$FOUND" != 0 ] && found_reboot_modification

#ENDE --- Aenderungen die einen Neustart benoetigen



if [ "$SYSTEMTYP" == "CLIENT" ]; then # client only
	#KODI Mysql Datenbanken vorbereiten
	if [ "$MYSQLDB" == "Eigene" ]; then
		MYSQLSOURCE="_"$HOSTNAME
#		[ -e /root/.kodi/userdata/Thumbnails_eigene ] || mkdir /root/.kodi/userdata/Thumbnails_eigene
#		rm /root/.kodi/userdata/Thumbnails
#		ln -sf Thumbnails_eigene/ /root/.kodi/userdata/Thumbnails
	else
		MYSQLSOURCE=""
#		rm /root/.kodi/userdata/Thumbnails
#                ln -sf /nfs/vdrserver/kodi/Thumbnails/ /root/.kodi/userdata/Thumbnails
	fi
	sed -i -e 's/host.*\/host/host\>'$SERVERIP'\<\/host/g' $KODICONFDIR/userdata/advancedsettings.xml
	sed -i -e 's/name.*kodi_video.*\/name/name\>kodi_video'$MYSQLSOURCE'\<\/name/g' $KODICONFDIR/userdata/advancedsettings.xml
	sed -i -e 's/name.*kodi_music.*\/name/name\>kodi_music'$MYSQLSOURCE'\<\/name/g' $KODICONFDIR/userdata/advancedsettings.xml

fi

if [ "$SYSTEMTYP" == "SERVER" ]; then # server only
#Adresse des NAS Servers testen
. $SCRIPTDIR/.set_nas_hdds
fi

if [ "$SYSTEMTYP" == "CLIENT" ]; then # client only
	#KODI Start-Grafik pruefen
#	if [ -z "$(ls -l /root/.kodi/media/Splash.png | grep Splash$KODISPLASH)" ]; then
#		ln -sf $IMAGEDIR/KODI_Splash"$KODISPLASH".png /root/.kodi/media/Splash.png
#	fi

	#commands.conf pruefen
	if [ "$(cat $VDRCONFDIR/commands.conf | grep "ping -c10 $SERVERIP" | sed 's/^.*ping -c10 //')" != "$SERVERIP" ]; then
		sed -i -e 's/\(ping -c10 \).*/\1'$SERVERIP'/' $VDRCONFDIR/commands.conf
		VDRRESTART=2
	fi
	if [ "$(cat $VDRCONFDIR/commands.conf | grep wakeonlan | sed -e 's/.*wakeonlan \(.*\)\".*/\1/')" != "$SERVERMAC" ]; then
		sed -i -e 's/\(wakeonlan \).*\(\".*\)/\1'$SERVERMAC'\2/' $VDRCONFDIR/commands.conf
#		sed -i -e 's/\(wakeonlan \).*\(\".*\)/\1'$(echo ${SERVERMAC:0:2}:${SERVERMAC:2:2}:${SERVERMAC:4:2}:${SERVERMAC:6:2}:${SERVERMAC:8:2}:${SERVERMAC:10:2})'\2/' $VDRCONFDIR/commands.conf
		VDRRESTART=3
	fi
fi

#Auswertung
logger -t CHECK "FOUND=$FOUND VDRRESTART=$VDRRESTART REBOOT=$REBOOT"
if [ "$REBOOT" != 0 ]; then
	echo "reboot"
	exit 0
fi
if [ "$VDRRESTART" != 0 ]; then
	echo "restart vdr"
	exit 0
fi
exit 0
