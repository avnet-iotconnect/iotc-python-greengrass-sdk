#!/bin/bash
cd "$(dirname "$0")"/..

set -e
set -x

which gdk > /dev/null
if [[ 0 != $? ]]; then
  python3 -m pip install -U git+https://github.com/aws-greengrass/aws-greengrass-gdk-cli.git@v1.6.2
fi

gdk component build

#obviously MYCPID will not work as default, but illustrating this as an example:
cpid="MYCPID"
env="poc"

if [ -n "$1" ]; then
  cpid="$1"
fi
if [ -n "$2" ]; then
  env"$2"
fi

IOTC_CONFIG=$(cat <<EOF
{
  "com.avnet.example.IotConnectGgBasicDemo": {
     "MERGE": {
      "IOTC_CPID": "${cpid}",
      "IOTC_ENV": "${env}"
    }
  }
}
EOF
)

sudo -E /greengrass/v2/bin/greengrass-cli \
  component details --name "com.avnet.example.IotConnectGgBasicDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --remove "com.avnet.example.IotConnectGgBasicDemo" | true

sudo -E /greengrass/v2/bin/greengrass-cli \
  deployment create \
  --recipeDir ${PWD}/greengrass-build/recipes \
  --artifactDir ${PWD}/greengrass-build/artifacts \
  --merge "com.avnet.example.IotConnectGgBasicDemo=0.0.1" \
  --update-config "$IOTC_CONFIG"
