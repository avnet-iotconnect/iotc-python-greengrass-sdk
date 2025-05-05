set -e
set -x

cd "$(dirname "$0")"/..

python3 -m venv ~/.venv-basic-demo

source ~/.venv-basic-demo/bin/activate

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

python3 -m pip install -r requirements.txt

if [ -n "$TMPDIR" ]; then
  rm -rf ~/tmp
  unset TMPDIR # for any future changes down below this line
fi
