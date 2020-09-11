#!/bin/bash
spotify_prefix="%{F#1DB954}%{F-} "
spotify_sufix=$(spotifyctl -q status --format '%title% - %artist%' --max-length 35)

echo "$spotify_prefix$spotify_sufix"


