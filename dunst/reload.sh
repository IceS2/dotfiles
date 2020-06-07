#!/bin/bash
backg=$(xgetres color0)
foreg=$(xgetres color7)
hl=$(xgetres color4)

pkill dunst

dunst -conf $HOME/.config/dunst/dunstrc -lf "$foreg" -nf "$foreg" -cf "$foreg" -lb "$backg" -nb "$backg" -cb "$backg" -frame_color "$hl" &

notify-send -u critical "Test message: critical test 1"
notify-send -u normal "Test message: normal test 2"
notify-send -u low "Test message: low test 3"
notify-send -u critical "Test message: critical test 4"
notify-send -u normal "Test message: normal test 5"
notify-send -u low "Test message: low test 6"
notify-send -u critical "Test message: critical test 7"
notify-send -u normal "Test message: normal test 8"
notify-send -u low "Test message: low test 9"
