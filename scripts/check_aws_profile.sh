#!/usr/bin/env bash

INI_FILE=~/.aws/credentials

while IFS=' = ' read key value
do
  if [[ $key == \[*] ]]; then
    section=$key
  elif [[ $value ]] && [[ $section == '[default]' ]]; then
    if [[ $key == 'aws_access_key_id' ]]; then
      AWS_ACCESS_KEY_ID=$value
    elif [[ $key == 'aws_secret_access_key' ]]; then
      AWS_SECRET_ACCESS_KEY=$value
    fi
  elif [[ $value ]] && [[ $section == '[data-intelligence]' ]]; then
    if [[ $key == 'aws_access_key_id' ]]; then
      PROD_AWS_ACCESS_KEY_ID=$value
    elif [[ $key == 'aws_secret_access_key' ]]; then
      PROD_AWS_SECRET_ACCESS_KEY=$value
    fi
  elif [[ $value ]] && [[ $section == '[ifood-data-dev]' ]]; then
    if [[ $key == 'aws_access_key_id' ]]; then
      DEV_AWS_ACCESS_KEY_ID=$value
    elif [[ $key == 'aws_secret_access_key' ]]; then
      DEV_AWS_SECRET_ACCESS_KEY=$value
    fi
  fi
done < $INI_FILE

if [ "$AWS_ACCESS_KEY_ID" = "$PROD_AWS_ACCESS_KEY_ID" ] && [ "$AWS_SECRET_ACCESS_KEY" = "$PROD_AWS_SECRET_ACCESS_KEY" ]; then
  export AWS_PROFILE="data-intelligence"
elif [ "$AWS_ACCESS_KEY_ID" = "$DEV_AWS_ACCESS_KEY_ID" ] && [ "$AWS_SECRET_ACCESS_KEY" = "$DEV_AWS_SECRET_ACCESS_KEY" ]; then
  export AWS_PROFILE="ifood-data-dev"
fi
