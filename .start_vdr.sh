#!/bin/bash
# v1.0 all clients

. /etc/vectra130/configs/sysconfig/.sysconfig

[ ! -e .frontend.sh ] && nice -$_watchdog_sh_nice $SCRIPTDIR/.frontend.sh &

exit 0
