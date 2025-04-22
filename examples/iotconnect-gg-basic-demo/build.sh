#!/bin/bash

set -e

cd "$(dirname "$0")"

cpid="$1"
env="$2"

if [[ -z "${cpid}" || -z "${env}" ]]; then
  echo "Usage:"
  echo " $0 <cpid> <env>"
  exit 1
fi

which gdk > /dev/null
if [[ 0 != $? ]]; then
  python3 -m pip install -U git+https://github.com/aws-greengrass/aws-greengrass-gdk-cli.git@v1.6.2
fi

if [[ -n "$PACKAGE_LOCAL_SDK" ]]; then
  # Optional: Set this value to anything to build and package local SDK source as well.
  ../../scripts/package.sh
  mkdir -p local-packages/
  cp -f ../../dist/*.whl local-packages/
fi

gdk component build

recipe=greengrass-build/recipes/recipe.yaml
sed -i "s#MYCPID#${cpid}#g" ${recipe}
sed -i "s#MYENV#${env}#g" ${recipe}
echo "Recipe for ${cpid}:${env} is generated at ${recipe}. Upload THIS recipe to /IOTCONNECT"
