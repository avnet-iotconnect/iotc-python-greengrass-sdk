#!/bin/bash

set -e
set -x

bundle_path="$1"

function print_usage {
  echo "usage $0 <bundle_path>"
  echo " <bundle_path> - The zip file with device credentials downloaded from /IOTCONNECT."
  echo "${1}"
}

if [[ -z "${bundle_path}" ]]; then
  print_usage "Bundle path argument is required"
  exit 1
fi

if [[ ! -f "${bundle_path}" ]]; then
  print_usage "Bundle file ${bundle_path} does not exist"
  exit 1
fi

# if we are in different directory, record the full path...
bundle_path=$(realpath "$bundle_path")

apt update

grep -q OpenSTLinux /etc/os-release || print_usage "OpenSTLinux not detected."

# we will use git later in the script
# cmake to build awscrt native bindings, and awscrt is required by awsiotsdk
# sudo for script compatibility - even though greengrass runs as root (I guess ST wanted to simplify and sacrifice security)
apt install -q -y --upgrade python3 python3-pip python3-venv python3-wheel git cmake sudo || \
  print_usage "Failed to install required APT packages. Check your internet connection and that your board's image is upgraded to the latest."

# It should be the case that mp1 is armv7l and the mp2 should be aarch64
# Use only revisions that are known to work. We don't want future changes to break something.
if [[ "$(uname -m)" == "armv7l" ]]; then
  st_repo=STM32MP1_AWS-IoT-Greengrass-nucleus-lite
  st_revision=7585a4de19ae9726995eb27df732a720f47af527

  # We are low on RAM and can afford to disable these services:
  sudo systemctl stop weston-graphical-session.service
  sudo systemctl stop netdata.service

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

  mkdir -p ~/iotc-wheelhouse\
  # TODO: Big issue here - Greengrass runs with HOME=/root for some reason and not /home/root
  # "Fix" for now with the symlink
  mkidr -p /root # should be there, but just in case...
  if [[ ! -h /root/iotc-wheelhouse ]]; then
    ln -sf ~/iotc-wheelhouse /root/
  fi
  pushd ~/iotc-wheelhouse >/dev/null
  set +x # avoid output confusion
  echo "This directory contains cached wheel files, some of which are required for the /IOTCONNECT SDK. Do not remove these." \
    > README.txt
  echo "--------------------------------------------"
  echo "               IMPORTANT"
  echo " The setup process will now build some python packages from source."
  echo " During this process, the graphical session will be temporarily shut down."
  echo " This process take around 50 minutes, so please be patient..."
  echo "--------------------------------------------"
  set -x
  python3 -m venv ~/venv-wheelhouse # not exactly sure if we need venv, but just to be safe..
  source ~/venv-wheelhouse/bin/activate
  mkdir -p ~/tmp
  export TMPDIR=~/tmp
  python3 -m pip wheel awsiotsdk==1.22.2 psutil==7.0.0
  unset TMPDIR
  rm -rf ~/tmp
  deactivate
  rm -rf ~/venv-wheelhouse
  echo "Done pre-building python packages."
  sudo systemctl daemon-reload # avoid warnings when attempting to start the service below... Not sure why this happens
  sudo systemctl start netdata.service
  sudo systemctl start weston-graphical-session.service

  popd >/dev/null # ~/iotc-wheelhouse


elif [[ "$(uname -m)" == "aarch64" ]]; then
  st_repo=STM32MP2_AWS-IoT-Greengrass-nucleus-lite
  st_revision=54292e3f7d64ec84a880e9bb727e5f7836409f1b
else
  echo "Unknown architecture. Exiting..."
  exit 1
fi

rm -rf "${st_repo}"
git clone "https://github.com/stm32-hotspot/${st_repo}.git"
pushd "${st_repo}" >/dev/null
git reset --hard ${st_revision}
mkdir -p ~/gg_lite
cp -r gg_lite/* ~/gg_lite # 5_MPU_RunGGLite.sh the script expects the files to be in this location
mkdir -p ~/gg_lite/certs # their scrip will print an error out if this directory doesn't exist, so hush that

# don't run the nucleus just yet so that the logs are not stuffed with errors
# shellcheck disable=SC2016
sed -i '\#${GG_DIR}run_nucleus#d' 5_MPU_RunGGLite.sh
bash 5_MPU_RunGGLite.sh

# place config.yaml into /etc/greengrass
# place certs and private key into /var/lib/greengrass
unzip -q -o "${bundle_path}" config.yaml -d /etc/greengrass
unzip -q -o "${bundle_path}" -d /var/lib/greengrass
rm -f /var/lib/greengrass/config.yaml
curl -s "https://www.amazontrust.com/repository/AmazonRootCA1.pem" --output /var/lib/greengrass/AmazonRootCA1.pem

# (somewhat) fix permissions for the private key. We really would prefer that private key is not accessible by other users.
chmod o-rwx /var/lib/greengrass/pk_*.pem

# make things idempotent:
systemctl stop greengrass-lite.target >/dev/null 2>&1 || :

# now we can run the nucleus and clean up
bash ~/gg_lite/run_nucleus

popd >/dev/null # out of $repo..

rm -rf ~/gg_lite "${st_repo}" # cleanup. We don't need these files anymore

echo Done.

