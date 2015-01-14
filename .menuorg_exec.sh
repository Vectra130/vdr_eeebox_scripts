#!/bin/bash
# v1.0 all

# Befehle aus Menuorg ausfuehren

. /etc/vectra130/configs/sysconfig/.sysconfig

for ARG in $@ ; do
   KEY="${ARG/=*}"
   VALUE="${ARG/*=}"

   case $KEY in
        standalone)
                 STANDALONE=$VALUE
                 ;;
        option)
                OPTIONS+=$VALUE" "
                ;;
        app)
                 APP=$SCRIPTDIR/$VALUE
                 ;;
        display)
                XDISPLAY=$VALUE
                ;;
        *)
                 echo "unknown argument: $KEY"
                 ;;
    esac
done

# finished parsing arguments


# minimum required arguments
if [[ -z $APP || ! -x $APP ]]; then
        logger -t MENUORG_EXEC "minimum required argument (app) not given, or app missing. Exit now ..."
        exit 0
fi

if [ "x$STANDALONE" = "xyes" ]; then
	# Hier Standallone Kommando
	if [ ! -z $XDISPLAY ]; then
	   OPTIONS+="DISPLAY=:$XDISPLAY "
	   export DISPLAY=$XDISPLAY
	fi
else
   logger -t MENUORG_EXEC "Exec: $APP $OPTIONS"
#   eval $APP $OPTIONS
fi


