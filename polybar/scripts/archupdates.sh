#!/bin/bash

updates_arch=$(checkupdates | wc -l)

# if ! updates_aur=$(cower -u 2> /dev/null | wc -l); then
if ! updates_aur=$(trizen -Su --aur 2> /dev/null | wc -l); then
    updates_aur=0
fi

updates=$(("$updates_arch" + "$updates_aur"))

if [ "$updates" -gt 0 ]; then
    echo "$updates_arch %{F#D3D3D3}%{F-} $updates_aur"
else
    echo ""
fi
