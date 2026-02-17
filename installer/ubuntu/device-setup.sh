#!/bin/bash

set -e
set -x

connection_kit_path=${1}


function print_usage {
  echo "usage $0 <connection_kit_path>"
  echo " <connection_kit_path> - The zip file with device credentials downloaded from /IOTCONNECT."
}


if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root!"
  exit 1
fi

if [[ -z "${connection_kit_path}" ]]; then
  print_usage "connection_kit_path path argument is required"
  exit 2
fi

if [[ ! -f "${connection_kit_path}" ]]; then
  print_usage "Connectio Kit file ${connection_kit_path} does not exist"
  exit 3
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

apt update -y

# unzip required for the next steps
apt install -q -y unzip
# python3.12-venv for all /IOTCONNECT components, but it may be handled differently and already available on x86 ubuntu
apt install -q -y python3.12-venv || :

case $(uname -m) in
  aarch64) arch_suffix=arm64 ;;
  x86_64)  arch_suffix=x86-64 ;;
  *)       echo "Error: The installer does not support this system"; exit 1 ;;
esac

systemctl stop greengrass-lite.target || :
apt remove -y aws-greengrass-lite 2> /dev/null || :

zip_file=aws-greengrass-lite-deb-${arch_suffix}.zip
mkdir -p /tmp/ggl-download
pushd /tmp/ggl-download >/dev/null
wget -nv \
  "https://github.com/aws-greengrass/aws-greengrass-lite/releases/download/v2.3.2/${zip_file}" \
  -O "${zip_file}"
unzip -o "${zip_file}"
if [[ $release_ok != yes ]]; then
    echo "WARNING: This deb package will likely only install on Ubuntu 24.xx versions!"
fi

deb_package="$(ls -1 aws-greengrass-lite-*-Linux.deb | head -n1)"
systemctl stop greengrass-lite.target 2>/dev/null || :
apt remove -y aws-greengrass-lite >/dev/null 2>/dev/null || :
apt install -y ./"${deb_package}"
popd >/dev/null
rm -rf /tmp/ggl-download

# Unpack the kit/bundle and deploy the files into appropriate places with appropriate permissions
mkdir -p /tmp/iotc-config
pushd /tmp/iotc-config >/dev/null
unzip -q -o "${connection_kit_path}"

mv config.yaml /etc/greengrass/config.yaml
chmod a-x /etc/greengrass/config.yaml # just in case
mkdir -p /var/lib/greengrass/certs/
chown ggcore:ggcore /var/lib/greengrass/certs
chmod 775 /var/lib/greengrass/certs
# there should be only one pem and crt here, so this is fine
if [[ -f AmazonRootCA1.pem ]]; then
  # the new connection kit will have the proper files
  cp ./* /var/lib/greengrass/certs/
else
  # The may not have this AmazonRootCA1.pem . If it does not, then it's the old "bundle"
  cp ./*.crt /var/lib/greengrass/certs/device.pem.crt
  cp ./*.pem /var/lib/greengrass/certs/private.pem.key
  curl -s "https://www.amazontrust.com/repository/AmazonRootCA1.pem" --output /var/lib/greengrass/certs/AmazonRootCA1.pem
fi
chmod 660 /var/lib/greengrass/certs/*
chown ggcore:ggcore /var/lib/greengrass/certs/*

popd >/dev/null # /tmp/iotc-config
rm -rf /tmp/iotc-config

tee /etc/greengrass/config.d/iotconnect-certs.yaml > /dev/null << END
system:
  privateKeyPath: "/var/lib/greengrass/certs/private.pem.key"
  certificateFilePath: "/var/lib/greengrass/certs/device.pem.crt"
  rootCaPath: "/var/lib/greengrass/certs/AmazonRootCA1.pem"
END

systemctl enable greengrass-lite.target
systemctl restart greengrass-lite.target
