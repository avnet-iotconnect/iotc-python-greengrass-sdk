#!/bin/bash

set -e
set -x

connection_kit_path=${1}

function print_usage {
  echo "usage $0 <connection_kit_path>"
  echo " <connection_kit_path> - The zip file with device credentials downloaded from /IOTCONNECT."
  echo "${1}"
}

if [[ -z "${connection_kit_path}" ]]; then
  print_usage "connection_kit_path path argument is required"
  exit 1
fi

if [[ ! -f "${connection_kit_path}" ]]; then
  print_usage "Connectio Kit file ${connection_kit_path} does not exist"
  exit 1
fi

release_ok=no
if [ ! -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ] && [[ "$VERSION_ID" =~ ^24\. ]]; then
        release_ok=yes
    fi
fi

# if we are in different directory, record the full path...
connection_kit_path=$(realpath "$connection_kit_path")

# unzip required for the next steps
# python3.12-venv for all /IOTCONNECT components
sudo apt install -q -y unzip python3.12-venv

mkdir -p /tmp/ggl-download
pushd /tmp/ggl-download >/dev/null
wget \
  'https://github.com/aws-greengrass/aws-greengrass-lite/releases/download/v2.1.0/aws-greengrass-lite-ubuntu-arm64.zip' \
  -O aws-greengrass-lite-ubuntu-arm64.zip
unzip -o aws-greengrass-lite-ubuntu-arm64.zip
if [[ $release_ok != yes ]]; then
    echo "WARNING: This deb package will likely only install on Ubuntu 24.xx versions!"
fi
sudo apt install -y ./aws-greengrass-lite-2.1.0-Linux.deb
popd >/dev/null
rm -rf /tmp/ggl-download

# Unpack the kit/bundle and deploy the files into appropriate places with appropriate permissions
mkdir -p /tmp/iotc-config
pushd /tmp/iotc-config >/dev/null
unzip -q -o "${connection_kit_path}"

sudo mv config.yaml /etc/greengrass/config.yaml
sudo chmod a-x /etc/greengrass/config.yaml # just in case
sudo mkdir -p /var/lib/greengrass/certs/
sudo chown ggcore:ggcore /var/lib/greengrass/certs
sudo chmod 775 /var/lib/greengrass/certs
# there should be only one pem and crt here, so this is fine
if [[ -f AmazonRootCA1.pem ]]; then
  # the new connection kit will have the proper files
  sudo cp ./* /var/lib/greengrass/certs/
else
  # The may not have this AmazonRootCA1.pem . If it does not, then it's the old "bundle"
  sudo cp ./*.crt /var/lib/greengrass/certs/device.pem.crt
  sudo cp ./*.pem /var/lib/greengrass/certs/private.pem.key
  sudo curl -s "https://www.amazontrust.com/repository/AmazonRootCA1.pem" --output /var/lib/greengrass/certs/AmazonRootCA1.pem
fi
sudo chmod 660 /var/lib/greengrass/certs/*
sudo chown ggcore:ggcore /var/lib/greengrass/certs/*

popd >/dev/null # /tmp/iotc-config
rm -rf /tmp/iotc-config

sudo tee /etc/greengrass/config.d/iotconnect-certs.yaml > /dev/null << END
system:
  privateKeyPath: "/var/lib/greengrass/certs/private.pem.key"
  certificateFilePath: "/var/lib/greengrass/certs/device.pem.crt"
  rootCaPath: "/var/lib/greengrass/certs/AmazonRootCA1.pem"
END

sudo systemctl enable greengrass-lite.target
sudo systemctl restart greengrass-lite.target
