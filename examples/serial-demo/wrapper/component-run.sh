#!/bin/bash

set -e

cd "$(dirname "$0")"/..

source ~/.venv-serial-demo/bin/activate
python3 -u serial-demo.py "$@"
