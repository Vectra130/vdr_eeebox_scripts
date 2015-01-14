#!/bin/bash
# v1.0 eeebox

#
# NVIDIA Bugfix - kein Sound nach S3
####################################
. /etc/vectra130/configs/sysconfig/.sysconfig
  logger -t HDMI "Resette HDMI Port..."
#  for X in /tmp/.X11-unix/*; do
#    DISPLAY=`echo $X | sed s#/tmp/.X11-unix/X#:#`
#    USER=root
#    OUTPUT=`su -l -c "xrandr -display $DISPLAY -q | grep ' connected ' | awk '{print \\$1}'" $USER`
#      for PORT in $OUTPUT; do
#        su -l -c "xrandr -display $DISPLAY --output $PORT --off" $USER
#        su -l -c "xrandr -display $DISPLAY --output $PORT --auto" $USER
DISPLAY=:1.0 xrandr --output HDMI-0 --off
DISPLAY=:1.0 xrandr --output HDMI-0 --auto
DISPLAY=:1.0 xrandr -r $HDMIFREQ

        logger -t HDMI "Port-Reset durchgeführt"
#      done
#  done
