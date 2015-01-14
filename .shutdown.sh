#!/bin/bash
# v1.0 eeebox

#Shutdown VOR-Script
#Wird anstatt des init scripts ausgefuehrt

. /etc/vectra130/configs/sysconfig/.sysconfig

ACTION=$0
ACTION=$(basename $ACTION)
ACTION2="$@"


showscreeninfo(){
	killall -9 .frontend.sh
        . $SCRIPTDIR/.stopallmultimedia
        killall -9 -q .showscreenimage.sh
	tput -Tlinux clear > $KEYB_TTY
	clear
        $SCRIPTDIR/.showscreenimage.sh $IMG &
        sleep 5
}

logger -t POWEROFF "\'$ACTION $ACTION2\' wird eingeleitet"

case "$ACTION" in
reboot)
	/sbin/shutdown.exec -r now
	;;
poweroff)
	/sbin/shutdown.exec -h -P now
	;;
shutdown)
echo SHUTDOWN!!!
	/sbin/shutdown.exec $ACTION2
	;;
init)
	case $@ in
	  0)
		echo -e "\e[33mSystem geht in Standby\e[0m"
		$SCRIPTDIR/.suspend.sh
		exit 0
	  ;;
	  6)
		echo -e "\e[33mSystem geht in Standby\e[0m"
		$SCRIPTDIR/.suspend.sh
		exit 0
	  ;;
	  reboot)
		IMG=reboot
		showscreeninfo
		/sbin/eeebox-init 6
		exit 0
	  ;;
	  poweroff)
		IMG=shutdown
		showscreeninfo
		/sbin/eeebox-init 0
		exit 0
	  ;;
	  *)
		echo -e "\e[33musage: init [0|6|poweroff|reboot]\e[0m"
		logger -t SHUTDOWN "\'$ACTION $ACTION2\' abgebrochen!!!"
	  ;;
	esac
	;;
esac
