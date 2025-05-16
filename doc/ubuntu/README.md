## Introduction

This guide provides the setup instructions to prepare the image 
for use with components that are using the /IOTCONNECT Greengrass SDK,
and install and run the Greengrass Lite Nucleus on PC and Raspberry Pi ARM 64-bit devices (generations 4 and 5).

## SD Card Image Flashing

Your device needs to have the Ubuntu 24.xx installed.
Older releases have not been tested and release 25 has been tested and will NOT work with this installer.
The preferred release is **Ubuntu Server 24.10**.

TBD: Guide. Eg. [https://www.youtube.com/watch?v=cHs_5bb9e7M&t=14s](https://www.youtube.com/watch?v=cHs_5bb9e7M&t=14s)

# Device Setup

Once your Greengrass device is created in /IOTCONNECT. Download the device credentials bundle
and transfer it them to the device with SCP or another utility. Use the package name in place of 
```my-device-bundle.zip``` in the step below.

Either clone this repo on the device and run [device-setup.sh](device-setup.sh) in this directory,
or directly download and run this script:
```shell
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/doc/raspberrypi/device-setup.sh -O device-setup.sh
bash device-setup.sh ~/my-device-bundle.zip
```

At this point, the device should show up as **Connected** in /IOTCONNECT within a minute or so.


