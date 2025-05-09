#!/bin/bash

set -e

cd "$(dirname "$0")"

./build.sh "$@"

sudo -E /greengrass/v2/bin/greengrass-cli \
  component details --name "io.iotconnect.example.IotConnectSdkDhmDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --remove "io.iotconnect.example.IotConnectSdkDhmDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --recipeDir greengrass-build/recipes \
  --artifactDir greengrass-build/artifacts \
  --merge "io.iotconnect.example.IotConnectSdkDhmDemo=0.1.0"

exit 0
# DEVELOPMENT NOTE:
# This pattern can be used instead of the line above to inject runtime component configuration:

# shellcheck disable=SC2317
IOTC_CONFIG=$(cat <<EOF
{
  "io.iotconnect.example.IotConnectSdkDhmDemo": {
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
--merge "io.iotconnect.example.IotConnectSdkDhmDemo=0.0.5" \
--update-config "$IOTC_CONFIG"
