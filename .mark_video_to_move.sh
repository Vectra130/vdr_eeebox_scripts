#!/bin/bash
# v1.2 all clients

#VDR Aufnahmen in Liste ein und austragen

case $1 in

 add_cp)
	[ -e $2/.move ] && rm $2/.move
	echo "cp" > $2/.move
 ;;
 add_mv)
	[ -e $2/.move ] && rm $2/.move
	echo "mv" > $2/.move
 ;;
 remove)
	[ -e $2/.move ] && rm $2/.move
 ;;
 check)
	for i in $(find /vdrvideo00/ -type f -name .move | tr '\n' ' '); do
		if [ "x$(cat $i)" == "xmv" ]; then
			echo "$(basename $(dirname $(dirname $i))) (verschieben)"
			FIND=1
		elif [ "x$(cat $i)" == "xcp" ]; then
			echo "$(basename $(dirname $(dirname $i))) (kopieren)"
			FIND=1
		fi
	done
	[ "x$FIND" != "x1" ] && echo "*** Warteliste ist leer ***"
 ;;
esac

exit 0
