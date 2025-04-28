#!/bin/bash

set -e

cd "$(dirname "$0")"

./build.sh "$@"

sudo -E /greengrass/v2/bin/greengrass-cli \
  component details --name "com.avnet.example.IotConnectGgBasicDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --remove "com.avnet.example.IotConnectGgBasicDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --recipeDir greengrass-build/recipes \
  --artifactDir greengrass-build/artifacts \
  --merge "com.avnet.example.IotConnectGgBasicDemo=0.0.1"

exit 0
# DEVELOPMENT NOTE:
# This pattern can be used instead of the line above to inject runtime component configuration:

# shellcheck disable=SC2317
IOTC_CONFIG=$(cat <<EOF
{
  "com.avnet.example.IotConnectGgBasicDemo": {
     "MERGE": {
      "IOTC_CPID": "${IOTC_CPID}",
      "IOTC_ENV": "${IOTC_ENV}"
    }
  }
}
EOF
)

# shellcheck disable=SC2317
sudo -E /greengrass/v2/bin/greengrass-cli \
deployment create \
--recipeDir ${PWD}/greengrass-build/recipes \
--artifactDir ${PWD}/greengrass-build/artifacts \
--merge "com.avnet.example.IotConnectGgBasicDemo=0.0.1" \
--update-config "$IOTC_CONFIG"
