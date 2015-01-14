# v1.0 eeebox

## X-Screen for the monitor.
#DISPLAY1=":1.0"
# auto detection for nvidia binary blob only
SCREEN1=$(nvidia-settings -q Screens | fgrep '.0' | cut -d ':' -f2 | cut -c1-3)
DISPLAY1=":$SCREEN1"
echo "Display1 (Monitor) is on    $DISPLAY1"
