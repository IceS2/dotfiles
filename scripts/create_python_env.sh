#!/bin/bash

PYTHON_VERSION=$1
DEFAULT_ENV_NAME=${PWD##*/}
VENV_NAME=${2:-${DEFAULT_ENV_NAME}}

pyenv local $PYTHON_VERSION
pyenv virtualenv $VENV_NAME
rm .python-version
echo ${VENV_NAME} > .python-version
pip install ipython
pip install neovim
