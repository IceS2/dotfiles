#!/bin/bash

RED="#FF4326"
YELLOW="#E2FF26"
GREEN="#26FF43"
DISABLED="#707880"

IFS=
connected_interfaces=$(nmcli d | rg '\bconnected' | awk '{print $2}')


wired=""
wifi=""
vpn=""

while read -r interface; do
  if [[ "$interface" = "ethernet" ]]; then
          wired="%{F$GREEN}%{F-}"
  elif [[ "$interface" = "wifi" ]]; then
          signal=$(nmcli d wifi | grep '*' | awk '{print $8}')
          if [[ $signal -lt 30 ]]; then
            color=$RED
          elif [[ $signal -lt 80 ]]; then
            color=$YELLOW
          else
            color=$GREEN
          fi
          signal=$(printf %3s $signal)
          wifi="%{F$color}%{F-} $signal%"
  elif [[ "$interface" = "tun" ]]; then
          vpn_name=$(nmcli d | rg '\bconnected' | rg '.*tun.*' | awk '{print $5}')
          vpn="%{F$GREEN}%{T7}VPN%{F-}%{T-} $vpn_name"
  elif [[ "$interface" = "" ]]; then
          echo "%{F$RED}%{F-}%{F$DISABLED} Offline%{F-}"
  fi
done < <(echo $connected_interfaces)

if [[ $wired && ($wifi || $vpn) ]]; then
  wired="$wired    "
fi

if [[ $wifi && $vpn ]]; then
  wifi="$wifi    "
fi

output="$wired$wifi$vpn"
echo $output
