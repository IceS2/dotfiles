#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Mudar nome das abas no Terminator
tt() { printf '\e]2;%s\a' "$*"; }

# Customize to your needs...

# Virtualenv aliases
alias default='source /home/pablo/virtualenvs/default/bin/activate'


# App aliases
alias datagrip='sh /home/pablo/Apps/DataGrip-2016.3.2/bin/datagrip.sh'
alias franz='/home/pablo/Apps/Franz/Franz &'
alias pycharm='sh /home/pablo/Apps/pycharm-2016.3.2/bin/pycharm.sh'

# Server aliases
alias airflow-server='ssh -i ~/.ssh/bi.pem ubuntu@ec2-54-233-146-172.sa-east-1.compute.amazonaws.com'
alias bi-srver='ssh -i ~/.ssh/bi_srv bi@10.28.40.101'
alias bidmin-ssh='ssh -i ~/.ssh/bi.pem centos@bidmin.escale.com.br'

# Exported configs
export DB_CONFIG_FILE=/home/pablo/workspace/credentials/db.credentials
export LOG_CONFIG_FILE=/home/pablo/workspace/configs/log.cfg
export LOG_PATH=./logs/
export ZOHO_CONFIG_FILE=/home/pablo/workspace/credentials/zoho.credentials
export CELERY_CONF=/home/pablo/workspace/configs/celeryconf.py
export FLASK_GOOGLE_CREDENTIALS=/home/pablo/workspace/credentials/client_secret.json
export GOOGLE_P12=/home/pablo/workspace/projects/raw-mkt/conf/google.p12

export FLASK_APP=/home/pablo/workspace/projects/bidmin/run.py

export PROMPT_COMMAND='if [ "$(id -u)" -ne 0 ]; then echo "$(date "+%Y-%m-%d.%H:%M:%S") $(pwd) $(history 1)" >> ~/.logs/zsh-history-$(date "+%Y-%m-%d").log; fi'

export AIRFLOW_HOME=/home/pablo/workspace/airflow
