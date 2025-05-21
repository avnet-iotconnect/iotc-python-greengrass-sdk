This process has been tested with FRDM-IMX93, but it should support other IMX boards with that can load the 
6.6 scarthgap Linux release.

While the default image on the device's eMMC could work as well, and even be restored or upgraded using the *uuu* tool,
we recommend using an SD Card instead, so that the eMMC stays pristine and the images can be flashed quicker. 

From 
[this link](https://www.nxp.com/design/design-center/development-boards-and-designs/frdm-i-mx-93-development-board:FRDM-IMX93#software)
, download the FRDM-IMX93 Demo Images (LF_v6.6.36-2.1.0_images_FRDM_1.0_i.MX93) package.


Use an adequate tool for your system to flash the **imx-image-full-imx93frdm.rootfs.wic.zst** image - *dd* on Linux
, Rufus, Balena Etcher and similar on other OS-es. 

If on Ubuntu and using *dd*, plug in an SD card and unmount/eject it with ```umount /media/$USER/*```. 
Flash the image onto the SD Card from the extracted images package directory:
```bash
sudo apt install -y zstd
zstd -d --stdout imx-image-full-imx93frdm.rootfs.wic.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```
where sdX will be your SDcard device listed by ```lsblk```.


Consult the *FRDM i.MX 93 Development Board Quick Start Guide* from the 
[Documentation Section](https://www.nxp.com/design/design-center/development-boards-and-designs/frdm-i-mx-93-development-board:FRDM-IMX93#documentation)
on how to connect the USB ports, setup network, and configure the SW1 boot switch. To boot from an SD card
, ensure that the board's *SW1 BOOT* switches are set to *0011* (4 to 1) configuration
before booting up the device.

Connect to either the USB serial console, or SSH to the device as root user.

Download the IoTConnect Connection Kit for your device to the device.

At the console prompt enter:
```shell
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/doc/imx/device-setup.sh -O device-setup.sh
bash device-setup.sh ~/my-device-package.zip
```

At this point, the device should show up as **Connected** in /IOTCONNECT within a minute or so.
