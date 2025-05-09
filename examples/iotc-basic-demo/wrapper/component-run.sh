#!/bin/bash

set -e

cd "$(dirname "$0")"/..

source ~/.venv-basic-demo/bin/activate
python3 -u basic-demo.py "$@"
