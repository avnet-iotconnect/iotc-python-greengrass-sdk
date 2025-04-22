set -e
set -x

cd "$(dirname "$0")"/..

if grep OpenSTLinux /etc/issue > /dev/null; then
  #special setup for OpenSTLinux:
  sudo apt-get update
  sudo apt-get install -y --upgrade python3 python3-pip python3-venv
fi

python3 -m venv ~/.venv-iotc-gg-basic-demo

source ~/.venv-iotc-gg-basic-demo/bin/activate

if [[ -d ./local-packages ]]; then
  # This can be used to install or test local wheel packages like the SDK pre-release package
  python3 -m pip uninstall -y iotconnect-greengrass-sdk || true
  python3 -m pip install --upgrade --force-reinstall ./local-packages/*.whl
fi

python3 -m pip install -r requirements.txt
