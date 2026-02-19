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

# if we are in different directory, record the full path...
connection_kit_path=$(realpath "${connection_kit_path}")

apt update

grep -q OpenSTLinux /etc/os-release || print_usage "OpenSTLinux not detected."

# we will use git later in the script
# cmake to build awscrt native bindings, and awscrt is required by awsiotsdk
#  for script compatibility - even though greengrass runs as root (I guess ST wanted to simplify and sacrifice security)
apt install -q -y --upgrade python3 python3-pip python3-venv python3-wheel git cmake  || \
  print_usage "Failed to install required APT packages. Check your internet connection and that your board's image is upgraded to the latest."

function mp1_install_build_packages {
  # python binary packages are not as widely available for 32-bit ARM processors,
  # so sometimes the system will need to natively compile some packages.
  # Specifically awsiotsdk will be needed by all our Greengrass Components it ant will want awscrt compiled.
  # python3-cffi would be needed to compile the cryptography package on MP1's. May be needed in the future
  # for the iotconnect-rest-api python package.
  # The rest of the packages would setup a proper development environment.
  echo Installing development packages...
  rm -rf ~/tmp-apt
  mkdir -p ~/tmp-apt
  pushd ~/tmp-apt >/dev/null
  apt -q -y install python3-cffi make gcc g++ gcc-symlinks cpp-symlinks g++-symlinks binutils libc6-extra-nss libnss-db2 libc-malloc-debug0
  curl -s -O "https://downloads.iotconnect.io/partners/st/packages/deb/arm7l/mp1-apt-dev-pack.tar.gz"
  tar xf mp1-apt-dev-pack.tar.gz
  rm mp1-apt-dev-pack.tar.gz
  chown root:root ./*.deb
  dpkg -i ./*.deb
  popd >/dev/null
  rm -rf ~/tmp-apt
  echo Done installing development packages.
}

function mp2_install_build_packages {
  # Sometimes the system will need to natively compile some packages.
  # Specifically awsiotsdk will be needed by all our Greengrass Components it ant will want awscrt compiled.
  # python3-cffi would be needed to compile the cryptography package on the device. May be needed in the future
  # for the iotconnect-rest-api python package.
  # The rest of the packages would setup a proper development environment.
  echo Installing development packages...
  apt -q -y install python3-cffi make gcc g++ gcc-symlinks cpp-symlinks g++-symlinks binutils libc6-extra-nss libnss-db2 libc-malloc-debug0
  echo Done installing development packages.
}

function mp1_build_wheel_cache {
  # Pre-build python packages needed by the SDK and demos.
  # Otherwise this would take very long time during component installs

  # We are low on RAM and can disable these service go tet most of it back for now:
  systemctl stop weston-graphical-session.service
  systemctl stop netdata.service

  mkdir -p /var/cache/iotconnect/wheelhouse
  pushd /var/cache/iotconnect/wheelhouse >/dev/null
  curl -s -O https://downloads.iotconnect.io/partners/st/packages/python/mp1/prebuilt-wheels-cp3x-armv7l.tgz
  tar zxvf prebuilt-wheels-cp3x-armv7l.tgz
  # in case the user has any as well...
  prebuilt_wheels=$(ls ~/prebuilt-wheels-*-armv7l.tgz 2>/dev/null || :)
  if [[ -n ${prebuilt_wheels} ]]; then
    echo "Installing the pre-built packages..."
    tar -zxvf "${prebuilt_wheels}"
  fi
  set +x # avoid output confusion
  echo "This directory contains cached wheel files, some of which are required for the /IOTCONNECT SDK. Do not remove these." \
    > README.txt
  echo "--------------------------------------------"
  echo " The setup process will download a set of python packages,"
  echo " check if they need to be built source and cache them on your system."
  echo " During this process, the graphical session will be temporarily shut down."
  echo " This process may take some time, so please be patient..."
  echo "--------------------------------------------"
  set -x
  if [[ -z $(swapon -s) ]]; then # make this idempotent
    if [[ ! -f /swapfile ]]; then
      echo "Creating the swap file..."
      dd if=/dev/zero of=/swapfile bs=1024 count=524288
    fi
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
  fi
  python3 -m venv ~/venv-wheelhouse # not exactly sure if we need venv, but just to be safe..
  echo "Creating the virtual environment..."
  source ~/venv-wheelhouse/bin/activate
  mkdir -p ~/tmp
  export TMPDIR=~/tmp
  echo "Building the packages..."
  python3 -m pip wheel --find-links=file:///var/cache/iotconnect/wheelhouse awsiotsdk==1.22.2 psutil==7.0.0
  unset TMPDIR
  rm -rf ~/tmp
  deactivate
  rm -rf ~/venv-wheelhouse
  echo "Done pre-building python packages."
  systemctl daemon-reload # avoid warnings when attempting to start the service below... Not sure why this happens

  # We don't need swap anymore
  swapoff /swapfile
  rm -f /swapfile

  # Restart the services that we stopped previously
  systemctl start netdata.service
  systemctl start weston-graphical-session.service

  popd >/dev/null # /var/cache/iotconnect/wheelhouse
}

function install_ggl {
  # We take the official AWS SDK package and install it without deps.
  # We manually install the dependencies.

  ### Install deps that should satisfy what the AWS package will need.
  # We will remove from the actual deps of the deb package later.
  apt install -y libzip uriparser

  ### Prepare the temporary work area
  rm -rf /tmp/ggl-install
  mkdir -p /tmp/ggl-install
  pushd /tmp/ggl-install>/dev/null

  ### Get the zip and extract the deb
  zip_file=aws-greengrass-lite-deb-${broad_arch}.zip
  rm -f "${zip_file}"
  wget -nv \
    "https://github.com/aws-greengrass/aws-greengrass-lite/releases/download/v2.3.2/${zip_file}" \
    -O "${zip_file}"
  rm -f -- *.deb
  unzip -q -o "${zip_file}"

  ### Remove deps from deb package and install it
  ### by exploding the deb, removing the Depends field from control and re-packing it.
  deb_package="$(ls -1 aws-greengrass-lite-*-Linux.deb | head -n1)"
  dpkg-deb -e "$deb_package"
  sed -i '/^Depends:/d' DEBIAN/control
  pushd DEBIAN >/dev/null
  tar -czf ../control.tar.gz .
  popd >/dev/null
  ar r "$deb_package" control.tar.gz
  rm -rf ./DEBIAN
  rm -f control.tar.gz

  ### Now install the deb without deps
  set +x # avoid output confusion
  echo "--------------------------------------------"
  echo " The setup process will now install the Greengrass Lite package."
  echo " This process may take some time..."
  echo "--------------------------------------------"
  set -x
  systemctl stop greengrass-lite.target 2>/dev/null || :
  apt remove -y aws-greengrass-lite >/dev/null 2>/dev/null || :
  dpkg -i "./${deb_package}"

  popd >/dev/null # out of $repo..
  rm -rf /tmp/ggl-install
}

function setup_nucleus_credentials {
  connection_kit_path="${1}"
  mkdir -p /tmp/iotc-config
  pushd /tmp/iotc-config >/dev/null
  unzip -q -o "${connection_kit_path}"
  # replace with proper nucleus
  sed -ie 's:{{nucleus_component}}:aws.greengrass.NucleusLite:g' config.yaml
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
}

# It should be the case that mp1 is armv7l and the mp2 should be aarch64
# Use only revisions that are known to work. We don't want future changes to break something.
if [[ "$(uname -m)" == "armv7l" ]]; then
  broad_arch=armv7
  st_repo=STM32MP1_AWS-IoT-Greengrass-nucleus-lite
  st_revision=c10b35f73eec09bdc9818a67e871304966db74d4
  mp1_install_build_packages
  mp1_build_wheel_cache
elif [[ "$(uname -m)" == "aarch64" ]]; then
  broad_arch=arm64
  mp2_install_build_packages
  st_repo=STM32MP2_AWS-IoT-Greengrass-nucleus-lite
  st_revision=7bb5243512bc18fffef75fd7d7df728f8cba7725
else
  echo "Unknown architecture. Exiting..."
  exit 1
fi

install_ggl
setup_nucleus_credentials "${connection_kit_path}"

systemctl enable greengrass-lite.target
systemctl restart greengrass-lite.target

echo Done.
