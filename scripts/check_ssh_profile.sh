#! /bin/bash

SSH_PUB_KEY="$HOME/.ssh/id_rsa.pub"

domain=$(awk '{split($0, a, "@"); print a[2]}' $SSH_PUB_KEY)

if [ "$domain" = "ifood" ]; then
  export SSH_PROFILE="iFood"
elif [ "$domain" = "undercity" ]; then
  export SSH_PROFILE="IceS2"
fi
