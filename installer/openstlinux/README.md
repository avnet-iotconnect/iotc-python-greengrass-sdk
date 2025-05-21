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
As an alternative, we suggest to explore the option of downloading the starter package, 
and running the *create_sdcard_from_flashlayout.sh* utility instead in the scripts directory
of the package in order to create an SD card image. 
This SD card image can be then flashed onto the SD card with the *dd* 
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

> [NOTE!]
> This step may take almost an hour on MP1 due to the installer needing to precompile some packages

At this point, the device should show up as **Connected** in /IOTCONNECT within a minute or so.

# Known Issues

## ROOT_HOME and Systemd

If running component lifecycle steps with ```RequiresPrivilege: true``` or even any Systemd services,
please note that root's HOME environment variable will be pointing to ```/root```, rather than ```/home/root``` - which is 
the actual root's home. This has to do with the way Systemd/initd services will be setting root's home to 
a hardcoded value of /root on any system.

Since both directories exist, this may not be as big of an issue, but the inconsistency could cause a confusion where
Greengrass components or system services are placing or looking for files in places where one does not expect them to be.

If this needs to be addressed in your case, you can work around this issue at runtime by linking /root to /home/root, 
or when building their yocto image, you can make sure that bitbake *local.conf* sets the 
[root's home](https://docs.yoctoproject.org/4.3.1/ref-manual/variables.html#term-ROOT_HOME) 
to ```/root``` like this:
```
ROOT_HOME = "/root"
```

