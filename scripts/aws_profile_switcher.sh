#! /bin/bash

profile=$1
ACTIVE_PROFILE_PATH="$HOME/.aws/active_profile"

if [ "$profile" = "prod" ]; then
  export AWS_PROFILE="data-intelligence"
  echo "data-intelligence" > $ACTIVE_PROFILE_PATH
elif [ "$profile" = "dev" ]; then
  export AWS_PROFILE="ifood-data-dev"
  echo "ifood-data-dev" > $ACTIVE_PROFILE_PATH
fi

