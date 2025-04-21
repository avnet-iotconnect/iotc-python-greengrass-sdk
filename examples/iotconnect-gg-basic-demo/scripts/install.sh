set -e
set -x

cd "$(dirname "$0")"/..

if grep OpenSTLinux /etc/issue > /dev/null; then
  #special setup for OpenSTLinux:
  sudo apt-get update
  sudo apt-get install -y --upgrade python3 python3-pip
fi

python3 -m venv ~/.venv-iotc-gg-basic-demo

source ~/.venv-iotc-gg-basic-demo/bin/activate

# TODO: python3 -m pip install -r requirements.txt

c=iotc-python-sdk-lib
rm -rf /tmp/$c
mkdir -p /tmp/$c
# no dot files and ven etc
cp -r /avnet/$c/* /tmp/$c
python3 -m pip install --quiet /tmp/$c

c=iotc-python-greengrass-sdk
rm -rf /tmp/$c
mkdir -p /tmp/$c
# no dot files and ven etc
cp -r /avnet/$c/* /tmp/$c
python3 -m pip install --quiet /tmp/$c

