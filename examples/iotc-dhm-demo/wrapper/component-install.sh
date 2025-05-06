#!/bin/bash

set -e
set -x

cd "$(dirname "$0")"/..

python3 -m venv ~/.venv-dhm-demo

source ~/.venv-dhm-demo/bin/activate

if [ "$(df --output=avail /tmp | tail -n 1)" -lt 524288 ];
  # Some STM32 MPx devices have 256 MB /tmp or less, and that's not enough to install awscrt (dependency of awsiotsdk)
  then echo "Detected less than 512MB available on /tmp. Applying a workaround for pip install."
  mkdir -p ~/tmp || :
  export TMPDIR=~/tmp
fi

if [[ -d local-packages ]]; then
  # This can be used to install or test local wheel packages, like the SDK pre-release package
  # before it is published to pip
  if find local-packages -maxdepth 1 -name "iotconnect_greengrass_sdk-*.whl"; then
    python3 -m pip uninstall -y iotconnect-greengrass-sdk || true
  fi
  python3 -m pip install --upgrade --force-reinstall ./local-packages/*.whl
fi


if grep OpenSTLinux /etc/issue > /dev/null && [[ $(uname -m) == armv7l ]]; then
  # Special setup for OpenSTLinux on MP1 where pre-compiled package for awscrt is not available on pip
  # Normally pip would compile those from source, but the build environment does not have everything needed to compile those
  mkdir -p ~/tmp-wheels
  awscrt_whl=awscrt-0.24.1-cp311-abi3-manylinux_2_28_armv7l.manylinux_2_31_armv7l.whl
  awsiotsdk_whl=awsiotsdk-1.22.2-py3-none-any.whl
  wget -q https://downloads.iotconnect.io/sdk/python/arm7l/$awscrt_whl -O ~/tmp-wheels/$awscrt_whl
  wget -q https://downloads.iotconnect.io/sdk/python/arm7l/$awsiotsdk_whl -O ~/tmp-wheels/$awsiotsdk_whl
  python3 -m pip install ~/tmp-wheels/$awscrt_whl ~/tmp-wheels/$awsiotsdk_whl
  rm -rf ~/tmp-wheels
fi


python3 -m pip install -r requirements.txt

if [ -n "$TMPDIR" ]; then
  rm -rf ~/tmp
  unset TMPDIR # for any future changes down below this line
fi
