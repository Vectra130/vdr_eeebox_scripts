#!/bin/bash

# v1.1 eeebox

. /etc/vectra130/configs/sysconfig/.sysconfig

	#Suspend to ram vorbereiten

        rm /tmp/.startsuspend-s3
	touch /tmp/.s2ram_active

        logger -t SUSPEND "System geht in Suspend"

	#frontend beenden
	killall -q -9 .frontend.sh

        # Aufraeumen
        echo "" > /var/log/debug
        echo "" > /var/log/error
	rm -r /var/lib/apt/lists/*
	rm -r /var/cache/apt/archives/*
	rm /tmp/.[a-zA-Z]*
	rm /tmp/[a-zA-Z]*
        sync && echo 3 > /proc/sys/vm/drop_caches

        # wichtige Aktionen vorm S3
        killall -q .watchdog.sh
	$SCRIPTDIR/.watchdog.sh kill
	expect -c "set echo \"-noecho\"; set timeout 10; spawn -noecho "$SCRIPTDIR"/.get_avr_infos.sh; expect timeout { exit 1 } eof { exit 0 }"
	stop avahi-daemon

        rmmod lirc_igorplugusb

        #Shutdown Aktionen (nur eine auswaehlen!!!)

        #poweroff
#       killall -9 -q oscam
#       killall -9 -q vdr-$VDRVERS
#       poweroff

        #Suspend to Swapfile
#       s2disk

        #Suspend to Ram
        #s2ram Watchdog starten
        $SCRIPTDIR/.s2ram_watchdog.sh &
        s2ram --force --acpi_sleep 1


	#Aufwachen

	#Aufwach Grafik setzen
	$SCRIPTDIR/.showscreenimage.sh wakeup &

        # aktionen nach dem Aufwachen
        modprobe lirc_igorplugusb
	if [ "$USEWLAN" == "1" ]; then
		. $SCRIPTDIR/.startwlan
	fi
	start avahi-daemon
        [ $(pidof -xs .watchdog.sh | wc -w) == 0 ] && nice -$_watchdog_sh_nice $SCRIPTDIR/.watchdog.sh &
	rm /tmp/.s2ram_active

	test -e /tmp/.powersave && rm /tmp/.powersave
	$SCRIPTDIR/.frontend.sh &

        logger -t SUSPEND "System ist wieder aufgewacht"

exit 0
