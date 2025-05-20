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

# if we are in different directory, record the full path...
connection_kit_path=$(realpath "${connection_kit_path}")

#### Install needed dependencies from bookworm debian repository
cat > /etc/apt/sources.list.d/bookworm.list <<END
deb [trusted=yes] http://deb.debian.org/debian bookworm contrib main non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian bookworm-updates contrib main non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian bookworm-backports contrib main non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian-security bookworm-security contrib main non-free-firmware
END
apt update -y
apt install -y liburiparser1 libzip4 libevent-2.1-7

### Permanently add these libraries to the system search path
mkdir -p /etc/ld.so.conf.d/
echo /usr/lib/aarch64-linux-gnu > /etc/ld.so.conf.d/aarch64-linux-gnu.conf
ldconfig

# we were temporarily introducing this deb repository
# so remove it, so that we leave the system in a "most compatible" state
rm -f /etc/apt/sources.list.d/bookworm.list
apt clean

#### Install the GGL deb
rm -rf /tmp/ggl-install
mkdir -p /tmp/ggl-install
pushd /tmp/ggl-install >/dev/null
deb_package=aws-greengrass-lite-2.1.0-Linux.deb
wget -q https://github.com/aws-greengrass/aws-greengrass-lite/releases/download/v2.1.0/aws-greengrass-lite-ubuntu-arm64.zip
unzip -q -o aws-greengrass-lite-ubuntu-arm64.zip
remove_all_deps() {
  deb_package="$1"
  dpkg-deb -e "$deb_package"
  sed -i '/^Depends:/d' DEBIAN/control
  pushd DEBIAN >/dev/null
  tar -czf ../control.tar.gz .
  popd >/dev/null
  ar r "$deb_package" control.tar.gz
  rm -rf ./DEBIAN
  rm -f control.tar.gz
}
# if we don't do this, apt will always complain about unmet dependencies, but our best option was to install similar ones
remove_all_deps ${deb_package}
dpkg -i "./${deb_package}"
popd >/dev/null
rm -rf /tmp/ggl-install


#### Unpack the kit/bundle and deploy the files into appropriate places with appropriate permissions
rm -rf /tmp/iotc-config
mkdir -p /tmp/iotc-config
pushd /tmp/iotc-config >/dev/null
unzip -q -o "${connection_kit_path}"

sudo mv config.yaml /etc/greengrass/config.yaml
sudo chmod a-x /etc/greengrass/config.yaml # just in case
sudo mkdir -p /var/lib/greengrass/certs
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

rm -rf /tmp/iotc-config

sudo tee /etc/greengrass/config.d/iotconnect-certs.yaml > /dev/null << END
system:
  privateKeyPath: "/var/lib/greengrass/certs/private.pem.key"
  certificateFilePath: "/var/lib/greengrass/certs/device.pem.crt"
  rootCaPath: "/var/lib/greengrass/certs/AmazonRootCA1.pem"
END

sudo systemctl enable greengrass-lite.target
sudo systemctl restart greengrass-lite.target

echo Done.
