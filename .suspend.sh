#!/bin/bash
# v1.4 eeebox

#Energiesparen (Suspend Mode)

if [ $(pidof -x $(basename $0) | wc -w) -gt 2 ]; then
	logger -t SUSPEND "Eine Instanz laeuft bereits ... breche ab"
	exit 0
fi

. /etc/vectra130/configs/sysconfig/.sysconfig

#Erst die einzelnen Funktionen anlegen
#Suspend starten
startsuspend(){
	[ -e /tmp/.force_suspend ] && rm /tmp/.force_suspend
        touch /tmp/.powersave
	#Suspend Screen setzen
	killall -9 -q .showscreenimage.sh
	if [ ! -e /tmp/.no_startsuspend_info ]; then
		i=.frontend.sh
		if [ $(pidof -xs $i | wc -l) != "0" ]; then
	                logger -t STOPALLMULTIMEDIA "beende $i"
	                killall -q $i &
	                WAIT=0
	                while true; do
	                        [ $(pidof -xs $i | wc -l) == "0" ] && break
	                        [ $WAIT == 8 ] && logger -t STOPALLMULTIMEDIA "sauberes beenden von $i nicht möglich"
	                        WAIT=$[ WAIT+1 ]
	                        sleep 0.5
	                done
	        fi
		$SCRIPTDIR/.showscreenimage.sh startsuspend &
		stopallmultimedia
	fi
	irexec $SYSCONFDIR/.irexec_suspend.conf &
        echo StandBy
        #aufraumen und memory cache leeren
        [ $(ls /tmp/ | wc -l) != "0" ] && rm -r /tmp/* > /dev/null
	[ $(ls /root/ | grep ^kodi_crashlog | wc -l) != "0" ] && rm /root/kodi_crashlog*
	[ $(ls /var/log/ | grep [.][1-9] | wc -l) != "0" ] && rm /var/log/*.[1-9]*
	echo "" > /var/log/debug
        sync && echo 3 > /proc/sys/vm/drop_caches

        logger -t SUSPEND "suspend"
#	stop syslog-ng
	killall -9 -q .showscreenimage.sh
	$SCRIPTDIR/.showscreenimage.sh suspend &
	[ -e /tmp/.no_startsuspend_info ] && rm /tmp/.no_startsuspend_info

}

#Suspend beenden
endsuspend(){
	[ -e /tmp/.force_suspend ] && rm /tmp/.force_suspend
	$SCRIPTDIR/.showscreenimage.sh blank &
	ls /nfs/vdrserver/ > /dev/null &
        test -e /tmp/.powersave && rm /tmp/.powersave
	test -e /tmp/.switchvdr && rm /tmp/.switchvdr
	start syslog-ng &
#	if [ $(pidof -xs automount | wc -l) == "0" ]; then
#		. $SCRIPTDIR/.set_videodir
#	fi
	logger -t SUSPEND "endsuspend"
	[ "$(pidof -xs .frontend.sh | wc -w)" == "0" ] && nice -$_watchdog_sh_nice $SCRIPTDIR/.frontend.sh &
        #Watchdog starten
        logger -t WATCHDOG "Starte Watchdogs"
        pidof -xs .watchdog.sh || nice -$_watchdog_sh_nice $SCRIPTDIR/.watchdog.sh &
	DISPLAY=:1.0 chvt $(echo $X_TTY | sed -e 's/\/dev\/tty//')
	echo Wakeup
	sed -i -e 's/Wakeup/StandBy/' $WWWDIR/config/commands
}

#poweroff
poweroff(){
if [[ "$(users | wc -w)" == 0 || -e /tmp/.force_suspend ]]; then
    [ -e /tmp/.force_suspend ] && rm /tmp/.force_suspend
    rm /etc/avahi/services/*
    $SCRIPTDIR/.set_avahi_startserver_info.sh unset
    /sbin/eeebox-init 0
    exit 0
fi
}

#s2ram
s2ram(){
if [[ "$(users | wc -w)" == 0 || -e /tmp/.force_suspend ]]; then
    [ -e /tmp/.force_suspend ] && rm /tmp/.force_suspend
    [ x$(vdr-dbus-send.sh /Remote remote.GetVolume | grep boolean | awk '{ print $2 }') == "xfalse" ] && vdr-dbus-send.sh /Remote remote.SetVolume variant:string:'mute'
    $SCRIPTDIR/.showscreenimage.sh startsuspend &
    killall .frontend.sh
    stopallmultimedia
    $SCRIPTDIR/.suspend2s3.sh &
fi
}

stopallmultimedia(){
    . $SCRIPTDIR/.stopallmultimedia
}





#Aktion wenn die Power-Taste an der Fernbedienung gedrueckt wird
touch /tmp/.block_irexec
killall -9 -q irexec
[[ "$1" != "" && "$1" != [0-9] ]] && POWEROFF=$1
case "$POWEROFF" in
    Ausschalten) # Powertaste startet SHUTDOWN
        if [ ! -e /tmp/.powersave ]; then

		expect -c "set echo \"-noecho\"; set timeout 10; spawn -noecho "$SCRIPTDIR"/.get_avr_infos.sh; expect timeout { exit 1 } eof { exit 0 }"
                poweroff

        else

                endsuspend

        fi


        ;;

    Sleep) # s2ram
	[ ! -e /tmp/.s2ram_active ] && s2ram
	;;

    Standby) #  SUSPEND
        if [ ! -e /tmp/.powersave ]; then

		expect -c "set echo \"-noecho\"; set timeout 10; spawn -noecho "$SCRIPTDIR"/.get_avr_infos.sh; expect timeout { exit 1 } eof { exit 0 }"
		startsuspend

	else

		endsuspend

	fi

	;;

    force)
	touch /tmp/.force_suspend
	s2ram
	;;
esac
[ "$(pidof -xs irexec | wc -l)" == "0" ] && irexec $SYSCONFDIR/.irexec.conf &
[ -e /tmp/.block_irexec ] && rm /tmp/.block_irexec
[ -e /tmp/.force_suspend ] && rm /tmp/.force_suspend

killall -q .suspend.sh
exit 0
