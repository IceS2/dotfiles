#! /bin/bash -x

profile=$1

if [ "$profile" = "prod" ]; then
  ifood-aws-login -u "$BITBUCKET_EMAIL" -p "$IAWSL" -r "data-intelligence:DataPlus_Access"
  export AWS_PROFILE="data-intelligence"
elif [ "$profile" = "dev" ]; then
  ifood-aws-login -u "$BITBUCKET_EMAIL" -p "$IAWSL" -r "ifood-data-dev:DataPlus_Access"
  export AWS_PROFILE="ifood-data-dev"
fi

