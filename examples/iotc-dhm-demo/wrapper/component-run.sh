#!/bin/bash

set -e

cd "$(dirname "$0")"/..

source ~/.venv-dhm-demo/bin/activate
python3 -u dhm-demo.py "$@"
