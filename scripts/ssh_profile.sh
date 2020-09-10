#! /bin/bash
SSH_DIR="$HOME/.ssh"

profile=$1

if [ "$profile" = "personal" ]; then
  cp $SSH_DIR/ices2 $SSH_DIR/id_rsa
  cp $SSH_DIR/ices2.pub $SSH_DIR/id_rsa.pub
  export SSH_PROFILE="IceS2"
elif [ "$profile" = "ifood" ]; then
  cp $SSH_DIR/ifood $SSH_DIR/id_rsa
  cp $SSH_DIR/ifood.pub $SSH_DIR/id_rsa.pub
  export SSH_PROFILE="iFood"
fi
