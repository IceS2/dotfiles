#! /bin/bash

ACTIVE_PROFILE_PATH="$HOME/.aws/active_profile"

active_profile=$(awk 'FNR == 1 {print $1}' $ACTIVE_PROFILE_PATH)

export AWS_PROFILE="$active_profile"
