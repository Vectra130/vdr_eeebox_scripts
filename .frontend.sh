#!/bin/bash
# v1.18 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

#restart-frontend beenden
killall -q -9 .restart-frontend.sh
killall -q -9 .suspend.sh

if [ ${DEBUGMODE} != YES ]; then
        LOG="/dev/null"
else
        LOG="/tmp/frontend.log"
fi

#Pruefen welches Frontend zuerst gestartet werden soll
if [ "${STARTWITH}" == "VDR" ]; then
        echo "1:"$(cat $VDRCONFDIR/setup.conf | grep CurrentChannel | awk -F= '{ print $2 }' | sed -e 's/ //g') > /tmp/.startvdr
fi
if [ -e /tmp/.startkodi ]; then
	test -e /tmp/.startvdr && rm /tmp/.startvdr
	test -e /tmp/.startkodi && rm /tmp/.startkodi
fi

#Bootvideo beenden
. $SCRIPTDIR/.killbootsplash

#StandBy prüfen
if [ -e /tmp/.startsuspend-s3 ]; then
	$SCRIPTDIR/.suspend2s3.sh
fi

[ -e /tmp/.powersave ] && rm /tmp/.powersave

while true; do

  . $SYSCONFDIR/.sysconfig

  #XServer starten
  if [ -e $SCRIPTDIR/.startX8 ]; then
	. $SCRIPTDIR/.startX8

	#testen ob Bildschirm eingeschaltet ist
	$SCRIPTDIR/.check_hdmi_connect.sh
  fi

	  #StreamingServer prüfen
	  $SCRIPTDIR/.startserver.sh
	  if [ x$? == x2 ]; then
		#Server Wakeup failed
		$SCRIPTDIR/.suspend.sh Standby &
		sleep 10
	  fi

	  if [ ! -e /tmp/.startvdr ]; then
	      if [ "${USEKODI}" == "1" ]; then
			# avahi Meldungen setzen
			$SCRIPTDIR/.change_avahi_info.sh kodi 1

			. $SCRIPTDIR/.startkodi
	      else
			echo "1:"$(cat $VDRCONFDIR/setup.conf | grep CurrentChannel | awk -F= '{ print $2 }' | sed -e 's/ //g') > /tmp/.startvdr
	      fi
	  else
	      if [ "${USEVDR}" == "1" ]; then
			# avahi Meldungen setzen
			$SCRIPTDIR/.change_avahi_info.sh vdr 1

			. $SCRIPTDIR/.startvdr
	      else
			test -e /tmp/.startvdr && rm /tmp/.startvdr
	      fi
	  fi
  # avahi Meldungen löschen
  $SCRIPTDIR/.change_avahi_info.sh vdr 0
  $SCRIPTDIR/.change_avahi_info.sh kodi 0
sleep 1
done
