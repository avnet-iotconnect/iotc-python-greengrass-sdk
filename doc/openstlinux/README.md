## Introduction

This guide provides the setup instructions to prepare the image 
for use with components that are using the /IOTCONNECT Greengrass SDK,
and install and run the Greengrass Lite Nucleus.

In order to install a Greengrass components that uses the 
/IOTCONNECT Greengrass SDK on STM32 OpenSTLinux devices,
the device should usually be updated to a newer image in order.  


The /IOTCCNNECT Greengrass SDK requires the awsiotsdk as a dependency, which requires awscli, 
which needs to be natively compiled while being installed. In order to natively compile, 
such Python packages certain tools need to present which are not available on the image provided 
by the factory, and hence require an image upgrade.

## Image Flashing

Follow the ST Instructions to flash the OpenSTLinux Starter Package image to your device at 
[https://wiki.st.com/stm32mpu/wiki/Category:OpenSTLinux_starter_packages](https://wiki.st.com/stm32mpu/wiki/Category:OpenSTLinux_starter_packages)

The instructions provided in this document are tested with the StarterPackage version 6.0.0. 
Keep in mind that once the package is downloaded, the actual version may differ. For example:
```5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06``` was tested with STM32 MP135F.

The overall process with STM32CubeProgrammer is fairly complex and lengthy. 
As an alternative, we suggest to explore the option of downloading the starter package instead, 
and running the *create_sdcard_from_flashlayout.sh* utility in the scripts directory
of the package in order to create an SD card image. 
This SD card image can be then flashed onto the SD card with the ``dd`` 
linux utility, Rufus, Balena Etcher and similar on other OS-es. 

# Device Setup

Once your Greengrass device is created in /IOTCONNECT. Download the device credentials 
and transfer them to the device.

Either clone this repo on the device and run [device-setup.sh](device-setup.sh) in this directory,
or directly download and run this script:
```shell
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/doc/openstlinux/device-setup.sh -O device-setup.sh
bash device-setup.sh ~/my-device-package.zip
```

At this point, the device should show up as **Connected** in /IOTCONNECT.

If the device does not connect, you can follow the ST's troubleshooting guide for 
[MP1](https://github.com/stm32-hotspot/STM32MP1_AWS-IoT-Greengrass-nucleus-lite/)
/[MP2](https://github.com/stm32-hotspot/STM32MP1_AWS-IoT-Greengrass-nucleus-lite/),
depending on your device. If the device still has issues, 
you can provide the logs in an /IOTCONNECT support ticket using the /IOTCONNECT Web UI.


