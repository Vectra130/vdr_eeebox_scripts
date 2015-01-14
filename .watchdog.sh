#!/bin/bash
# v1.6 all

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 3 ] && exit 0

#Watchdog fuer einige Dienste

. /etc/vectra130/configs/sysconfig/.sysconfig

checkTime(){
	tmpFile=/tmp/$1.time
	time=$2
	startWatchdog=0
	if [ ! -e $tmpFile ]; then
		date +%s > $tmpFile
		startWatchdog=1
	else
		timeNow=$(date +%s)
		timeLast=$(cat $tmpFile)
		timeDiff=$[ timeNow - timeLast ]
		if [ "$timeDiff" -ge "$time" ]; then
			date +%s > $tmpFile
			startWatchdog=1
		fi
	fi
}

if [ "$1" == "show" ]; then
	ls -a $SCRIPTDIR | grep -x "\..*_watchdog"
	logger -t WATCHDOG "gestartete watchdogs: $(echo -n $(ls -a $SCRIPTDIR/ | grep -x "\..*_watchdog"))"
	exit 0
fi

if [ "$1" == "kill" ]; then
        for wd in $($SCRIPTDIR/.watchdog.sh show); do
		logger -t WATCHDOG "töte watchdog $wd..."
                killall -q $wd
        done
	exit 0
fi

logger -t WATCHDOG "Watchdogs werden gestartet"
#$SCRIPTDIR/.watchdog.sh show

while true; do

	for WATCHDOG in $(ls -a $SCRIPTDIR | grep -x "\..*_watchdog_[0-9][0-9][0-9][0-9]"); do
		wdTime=$(echo $WATCHDOG | sed -e 's/.*_watchdog_//')
		wdName=$(echo $WATCHDOG | sed -e 's/\(_watchdog\)_.*/\1/')
		checkTime $wdName $wdTime
#echo "---"$startWatchdog"---"$wdName
		if [[ "$startWatchdog" == "1" && ! -e /tmp/$wdName.block ]]; then
			if [ $(echo $WATCHDOG | grep [0-9][0-9][0-9][0-9].sh | wc -l) == 1 ]; then
				$SCRIPTDIR/$WATCHDOG
			else
				. "$SCRIPTDIR/$WATCHDOG"
			fi
		fi
	done

sleep 1
done
