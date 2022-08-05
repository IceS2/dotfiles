#!/bin/bash

dunstctl set-paused toggle

[[ "$(dunstctl is-paused)" == "false" ]] && polybar-msg action "#dunst.hook.0"
[[ "$(dunstctl is-paused)" == "true" ]] && polybar-msg action "#dunst.hook.1"
