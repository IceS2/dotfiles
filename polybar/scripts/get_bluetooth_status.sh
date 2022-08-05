#!/bin/bash

if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
then
  echo "%{F#66ffffff}"
else
  if [ $(echo info | bluetoothctl | grep 'Device' | wc -c) -eq 0 ]
  then
    echo ""
  fi
  echo "%{F#2193ff} %{F-}$(bluetoothctl info | rg Name | sed -nE 's/^\s*Name:\s*(.*)$/\1/p')"
fi
