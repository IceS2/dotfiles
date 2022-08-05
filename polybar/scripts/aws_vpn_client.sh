#!/bin/bash

WINDOW_CLASS="AWS VPN Client"
window_exist=$(xdo pid -N "$WINDOW_CLASS" | wc -l)

if [[ $window_exist -gt 0 ]]; then
  wmctrl -x -a $WINDOW_CLASS
else
  exec "/opt/awsvpnclient/AWS VPN Client"
fi
