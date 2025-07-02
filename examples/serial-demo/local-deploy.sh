#!/bin/bash

set -e

cd "$(dirname "$0")"

./build.sh "$@"

sudo -E /greengrass/v2/bin/greengrass-cli \
  component details --name "io.iotconnect.example.IotConnectSdkSerialDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --remove "io.iotconnect.example.IotConnectSdkSerialDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --recipeDir greengrass-build/recipes \
  --artifactDir greengrass-build/artifacts \
  --merge "io.iotconnect.example.IotConnectSdkSerialDemo=2.1.0"
