#!/bin/bash
#Update Script v1.0
#Alle Configs werden gesichert
#Alle Dateien im Ordner COPY_FILES werden mit Pfadangabe kopiert

#Konfiguration
UPDATEVERSION="1.0.1"
REQUIREDVERSION="1.0.0"
FORCEFIRSTSTART="NO"

#Hier die Update Aktionen eintragen
main_update() {

#Dienste installieren/deinstallieren
#apt-get -y update >> $LOG
#aptitude -y install >> $LOG
#aptitude -y purge >> $LOG

#Dateien kopieren/loeschen/bearbeiten
mkdir /var/lib/nfs/v4recovery
rm /etc/apt/preferences
apt-get update
aptitude -y install libjansson4 libsqlite3-0 libgraphicsmagick++3
TMP=/etc/vectra130/configs/vdrconfig/.plugin_start.config
echo "VDRPLUGINtvscraper=1" >> $TMP
sort -u $TMP -o $TMP

return 0
}

############################
#AB HIER NICHTS AENDERN!!!!!
check_update() {
echo "##### check_update" >> $LOG
[ "$(cat /etc/vectra130/VERSION)" != "$REQUIREDVERSION" ] && return 2
return 0
}

get_version() {
echo "##### get_version"
UPDATEVERSION=$(ls /tmp/update_RasPi_*/.. | grep RasPi | grep -v tar | awk -F_ '{ print $3 }')
[ "X$UPDATEVERSION" == "X" ] && return 1
LOG=/etc/vectra130/update_"$UPDATEVERSION".log
echo "##########"$(date)"##########" > $LOG
echo "UPDATEVERSION="$UPDATEVERSION >> $LOG
return 0
}

showscreenimage() {
echo "##### showscreenimage" >> $LOG

killall -9 -q fbi
OPTIONS="-a -noverbose -T 2"
xinit /etc/X11/xinit/xinitrc &
sleep 1
echo 0 >> $LOG
clear > $KEYB_TTY
tput -Tlinux clear > $KEYB_TTY
rm -rf /tmp/.X*
killall -9 fbi
echo 1 >> $LOG
fbi $OPTIONS /tmp/update_RasPi_"$UPDATEVERSION"/screen_$image.png &
echo 2 >> $LOG
sleep 1
killall -9 -q Xorg
killall -9 -q xinit
echo 3 >> $LOG
return 0
}

prepare() {
echo "##### prepare" >> $LOG
#Vorbereitungen

#Alte Logs entfernen
rm /etc/vectra130/update_*.log | grep -v "$UPDATEVERSION"

#ins updateverzeichnis wechseln
cd /tmp/update_RasPi_"$UPDATEVERSION" || return 3

#configvars setzen
. /etc/vectra130/configs/sysconfig/.sysconfig

#Multimedia beenden
echo "# stopallmultimedia" >> $LOG
. $SCRIPTDIR/.stopallmultimedia

#weitere Dienste beenden
for daemon in .watchdog.sh irexec; do
echo "# kille Dienst: "$daemon >> $LOG
	killall -v -9 $daemon
done
for daemon in samba lirc; do
echo "# stoppe Dienst: "$daemon >> $LOG
	[ -e /etc/init.d/$daemon ] && /etc/init.d/$daemon stop &
done

#Update Grafik einblenden
image="update"
showscreenimage

#configs sichern
echo "# sichere configs" >> $LOG
rm -rv /etc/vectra130/backup >> $LOG
mkdir -pv /etc/vectra130/backup/vdrconfig >> $LOG
mkdir -pv /etc/vectra130/backup/xbmcconfig >> $LOG
cp -rv $VDRCONFDIR/* /etc/vectra130/backup/vdrconfig/ >> $LOG
cp -rv $XBMCCONFDIR/* /etc/vectra130/backup/xbmcconfig/ >> $LOG

#Ende der Vorbereitungen
return 0
}

update() {
echo "##### update" >> $LOG
#Update durchfuehren
main_update
#Dateien kopieren
for cpfile in $(find ./COPY_FILES/ -type f | sed 's/^\.\/COPY_FILES\///'); do
        cp -ruav COPY_FILES/"$cpfile" /"$cpfile" >> $LOG
done

#Patche anwenden
for patchfile in $(find ./PATCHES/ -type f | sed 's/^\.\/PATCHES\///'); do
        patch -p0 -N -i PATCHES/"$patchfile"
done
return 0
}

end_update() {
echo "##### end_update" >> $LOG
#Update Ende
#Abschliessende Aktionen
if [ "X$CLEANSTART" == "XYES" ]; then
echo "# firststart einleiten"
	sed -i -e 's/FIRSTSTART:0/FIRSTSTART:1/' $SYSCONFDIR/.config
	$SCRIPTDIR/.create_sysconfig.sh
	$SCRIPTDIR/.sysconf_changes.sh
fi
echo "$UPDATEVERSION" > /etc/vectra130/VERSION
return 0
}

update_fail() {
cat >> $LOG <<EOF
##############################################################################
Update Fehlgeschlagen!!!
Rueckgabewert = $?
# 0 = OK
# 1 = Versions Check
# 2 = Update Check
# 3 = Vorbereitungen
# 4 = Update
# 5 = Abschluss
EOF

image="updatefail"
showscreenimage
exit 0
}

update_ok() {
echo "##### Update OK" >> $LOG
image="updateok"
showscreenimage
sleep 10
}

#Update Ablauf
get_version
[ "$?" != 0 ] && update_fail
check_update
[ "$?" != 0 ] && update_fail
prepare
[ "$?" != 0 ] && update_fail
update
[ "$?" != 0 ] && update_fail
end_update
update_ok

#Neustart
echo "###Neustart" >> $LOG
/sbin/reboot

exit 0
