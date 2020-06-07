#!/bin/bash

sel=$(slop -f "-i %i -g %g")
sleep 1
shotgun $sel - | xclip -t 'image/png' -selection clipboard
