#!/bin/bash

set -e

cd "$(dirname "$0")"

if which gdk > /dev/null; then
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
if [[ -n ${IOTC_CPID} && -n ${IOTC_ENV} ]]; then
  echo "Applying CPID=${IOTC_CPID} and ENV=${IOTC_ENV} to default component configuration"
  sed -i "s#IOTC_CPID: null#IOTC_CPID: ${IOTC_CPID}#g" ${recipe}
  sed -i "s#IOTC_ENV: null#IOTC_ENV: ${IOTC_ENV}#g" ${recipe}
  if [[ -n ${IOTC_DUID} ]]; then
    echo "Applying DUID==${IOTC_DUID} to default component configuration"
    sed -i "s#IOTC_DUID: null#IOTC_DUID: ${IOTC_DUID}#g" ${recipe}
  fi
fi
echo "Recipe generated at ${recipe}. Upload THIS recipe to /IOTCONNECT"
