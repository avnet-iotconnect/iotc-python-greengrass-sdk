# Introduction

This repository provides the Avnet /IOTCONNECT AWS Greengrass SDK for building **Python-based Greengrass Components**, supporting both **AWS IoT Greengrass Nucleus Lite** 
(the C-based, ultra-lightweight edge runtime) and **AWS IoT Greengrass Nucleus Classic** (the full-featured Java-based runtime) ([Developer Guide][1], [AWS IoT Blog][2]).

With this SDK you can:
- **Use the provided example Components** to send telemetry, receive commands, and handle OTA updates (OTA push support coming soon)
- **Write your own Python Components** using the /IOTCONNECT 2.1 JSON protocol, with built-in helpers for `send_telemetry()`, command callbacks, and OTA lifecycle
- **Deploy Components and Firmware** via the IoTConnect Web UI (Device Template → Component registration → Firmware = set of Components → Deployment)

> **ℹ️ Note:** While examples may compile on other platforms, official guides, build scripts, and tested installers in this repo target **Linux** only.  

[1]: https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-lite-component.html  
[2]: https://aws.amazon.com/blogs/iot/aws-iot-greengrass-nucleus-lite-revolutionizing-edge-computing-on-resource-constrained-devices/

In order to run an /IOTCONNECT Greengrass Component using this SDK:
1. An /IOTCONNECT Device Template will need to be created, 
2. A Greengrass device will need to be created
3. A Nucleus will need to be set up and running on that device.
4. A Greengrass Component will need to built or downloaded.
5. A Greengrass Component will need to be registered in your /IOTCONNECT account.
6. A Firmware will need to be created, that defines which Components will be deployed to your Nucleus
7. The Firmware will need to be deployed to your target device.

# Board Specific QuickStart Guide(s)
* [STM32MP135F-DK](quickstart/QuickStart_STM32MP135F-DK.md)

Follow the steps below for details on how to complete each step for other target boards.

# Creating The Device Template 

Using the Sidebar menu in /IOTCONNECT, Navigate to *Device -> Greengrass Device -> Template (bottom menu)*. 
A Device Template that matches your application will need to be created. 
If testing our [examples](examples), you can upload the 
[common template JSON](examples/common/files/all-apps-device-template.json) 
that supports attributes and commands for examples by clicking on the **Create Template**
button and then the **Import** button.

# Creating The Device and Installing The Greengrass Nucleus

When creating an /IOTCONNECT Greengrass Device and Nucleus using the /IOTCONNECT Web UI:
* Name your device and select the template created in the previous step.
* Choose Nucleus Classic if your device supports java, Python 3.9+ and Python "venv" command.  
  * If using Nucleus Classic, execute the script provided by the website and the follow the online instructions.
* Choose Nucleus Lite if your OS-specific installer is available in the list below in this guide.
  * If using Nucleus Lite on Embedded Linux devices, download the device credential package bundle to the device 
  (using SCP for example) and follow the device-specific installer instructions below to install Nucleus Lite for 
  your specific Device/OS.
* Use your device package name in place of ```my-device-bundle.zip``` in the platform/OS-specific steps below.

### Greengrass Lite Installers

[comment]: <> (-------------------------------------------------------------------------)
<details>
<summary>Ubuntu 24.xx on Raspberry Pi ARM 64-bit devices (generations 4 and 5) or a PC</summary>

Either clone this repo on the device and run [installer/ubuntu/device-setup.sh](installer/ubuntu/device-setup.sh)
or directly download and run this script:

```shell
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/installer/ubuntu/device-setup.sh -O device-setup.sh
bash device-setup.sh ~/my-device-bundle.zip
```

</details>

[comment]: <> (-------------------------------------------------------------------------)

<details>
<summary>STM32 OpenSTLinux (MP1 or MP2 devices)</summary>

On MP1 devices The /IOTCONNECT Greengrass SDK requires the awsiotsdk as a dependency, which requires awscli, 
which needs to be natively compiled while being installed. In order to natively compile, 
such Python packages certain tools need to be present which are not available on the image provided 
by the factory, and hence require an image upgrade and along other steps laid out here that will 
upgrade the system tools and pre-compile the awsiotsdk dependencies.

### Image Flashing

Follow the ST Instructions to flash the OpenSTLinux Starter Package image to your device at 
[https://wiki.st.com/stm32mpu/wiki/Category:OpenSTLinux_starter_packages](https://wiki.st.com/stm32mpu/wiki/Category:OpenSTLinux_starter_packages)

The instructions provided in this document are tested with the StarterPackage version 6.0.0.
Keep in mind that once the package is downloaded, the actual version may differ. For example:
```5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06``` was tested with STM32 MP135F.

The overall process with STM32CubeProgrammer is fairly complex and can be lengthy. 
As an advanced but faster alternative, we suggest to explore the option of downloading the starter package, 
and running the *create_sdcard_from_flashlayout.sh* utility instead in the scripts directory
of the package in order to create an SD card image. 
This SD card image can then be flashed onto the SD card with the *dd* 
linux utility, Rufus, Balena Etcher and similar on other OS-es.

# Device Setup

Once your Greengrass device is created in /IOTCONNECT. Download the device credentials 
and transfer them to the device.

Either clone this repo on the device and run [installer/openstlinux/device-setup.sh](installer/openstlinux/device-setup.sh) in this directory,
or directly download and run this script:
```shell
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/installer/openstlinux/device-setup.sh -O device-setup.sh
bash device-setup.sh ~/my-device-package.zip
```

> This step may take more than 50 minutes on some devices, depending on your internet connection speed and device's CPU.
> This is due to the installer needing to set up the development environment and needing to precompile a set of Python packages.

## Known Issues

### ROOT_HOME and Systemd

If running Component Lifecycle steps with ```RequiresPrivilege: true``` or even any Systemd services,
please note that root's HOME environment variable will be pointing to ```/root```, rather than ```/home/root``` - which is 
the actual root's home. This has to do with the way Systemd/initd services will be setting root's home to 
a hardcoded value of /root on any system.

Since both directories exist, this may not have a large impact, but the inconsistency could cause a confusion where
Greengrass Components or system services are placing or looking for files in places where one does not expect them to be.

If this needs to be addressed, you can work around this issue at runtime by linking /root to /home/root, 
or when building their yocto image, you can make sure that bitbake *local.conf* sets the 
[root's home](https://docs.yoctoproject.org/4.3.1/ref-manual/variables.html#term-ROOT_HOME) 
to ```/root``` like this:
```
ROOT_HOME = "/root"
```

</details>

[comment]: <> (-------------------------------------------------------------------------)

<details>
<summary>IMX 6.6 scarthgap Linux releases</summary>

This process has been tested with FRDM-IMX93, but it should support other IMX MPU boards with that can load the 
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

At the console prompt enter:
```shell
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/installer/imx/device-setup.sh -O device-setup.sh
bash device-setup.sh ~/my-device-package.zip
```

</details>

[comment]: <> (-------------------------------------------------------------------------)

Once the device specific installer completes, The Greengrass Nucleus Lite should be running,
and the device should show up as **Connected** in /IOTCONNECT within a minute or so. 
You can proceed to develop and/or deploy your greengrass Component.

# About Example Components

We provide several Component examples with different sample use cases
to help you get started with AWS Greengrass on /IOTCONNECT.

See the README.md in corresponding example directories to learn more 
about how each Component interacts with the SDK and /IOTCONNECT:
* [Basic Demo](examples/basic-demo)
* [Device Health Monitoring Demo](examples/dhm-demo) 
* [Serial Port Demo](examples/serial-demo)

# Download Pre-Built Components

You can download the pre-built Components (ready to deploy) and skip the *Modifying and Building The Example Components* step below.

* Basic Demo: 
    [iotc-gg-component-basic-demo-2.1.0.zip](https://downloads.iotconnect.io/greengrass/components/iotc-gg-component-basic-demo-2.1.0.zip)
* Device Health Monitoring Demo: 
    [iotc-gg-component-dhm-demo-2.1.0.zip](https://downloads.iotconnect.io/greengrass/components/iotc-gg-component-dhm-demo-2.1.0.zip)
* Serial Port Demo:
    [iotc-gg-component-dhm-demo-2.1.0.zip](https://downloads.iotconnect.io/greengrass/components/iotc-gg-component-serial-demo-2.1.0.zip)

# Modifying and Building The Example Components

If you want to modify an example Component instead of using a fully pre-built version, you will need to clone this repo to your host PC where you will make your desired changes.

Navigate within the cloned repo to the ```/examples``` directory, and then to the demo that you wish to modify.

Make your modifications to the files as needed, and update the version numbers in ```gdk-config.json``` as well as ```local-deploy.sh``` to be unique to your new modified version.

>[!TIP]
> For example, if the current version of the demo in this repo is ```2.1.0```, it is recommended to make your modified versions ```2.1.1``` and then ```2.1.2```, etc.

After all of your modifications are saved, enter your IoTConnect CPID and Environment as shown here:

```shell
export IOTC_ENV=YourENV
export IOTC_CPID=YourCPID
```

>[!NOTE]
>Your CPID and Environment values can be obtained from **Settings -> Key Vault** on the /IOTCONNECT Web UI. 

At this point in time, it is not strictly necessary to provide these configuration values, and the SDK 
will use the information provided by the Greengrass environment to guess the MQTT topics that 
will be used to communicate to /IOTCONNECT, but in the future, more advanced SDK features may require this.

The build script will install **gdk** locally and build your Component such that 
the provided CPID and Environment values will be injected into the recipe.yaml.

Now you can execute ```build.sh``` (may require sudo privileges) to build your new Component version.

# Deploying Components

This guide will summarize some of the steps to deploy your Components with /IOTCONNECT, 
but for more details and a guide with screenshots, please refer to the 
[/IOTCONNECT Greengrass Quickstart](https://docs.iotconnect.io/iotconnect/quick-start/greengrass-device/).

Once your Component is built or the pre-built Component downloaded, 
you can upload the zip artifact along with the recipe from the
```greengrass-build``` directory of the Component. If building from source, 
Do **NOT** use the ```recipe.yaml``` from
the root directory of the example's source, as that recipe will need to be processed.

You can find all these Web UI pages in the *Firmware* (bottom of the screen) toolbar 
of the *Device -> Greengrass Device* 
section from the sidebar menu, with buttons at the top of the screen.

Click the **Components** button in the *Firmware* section and either to register a new Component by following the steps below, 
OR locate your existing Component and *Upgrade* it by clicking the **Upgrade** button 
on the right side of the Component entry.

A few extra steps are required before uploading your Component:
- If you built the component instead of using the pre-built option, rename your built Component zip in the ```greengrass-build``` directory to contain the version number that you entered into your files before you built. 
For example, rename basic-demo.zip to basic-demo-1.0.0.zip. The pre-built downloadable Components already have this.
- Once you upload your Component artifact (for example called ```basic-demo-2.1.0.zip```), click the copy icon on the right side panel next to the artifact that
was just upload, and edit recipe.yaml URI section located in the greengrass-build directory. For example:

```yaml
...
Manifests:
- Platform:
    os: linux
    runtime: '*'
  Artifacts:
  - Uri: s3://root-1233456/123456789-2854-4a77-8f3b-ca1696401e08/gg-artifacts/basic-demo-1.0.0.zip
    Unarchive: ZIP
  Lifecycle:
...
```

- Upload the modified recipe and create the Component by clicking the *Save* button.

Once the Components are registered with /IOTCONNECT, you need to click the **Create Firmware** button in the *Firmware* section.

Name your Firmware, select your previously created device template and set of Components that you want to deploy.
The Firmware only defines which Components will be managed by a deployment, so typically, this step should be done only once
assuming you will always be deploying the same set of Components.

You can search the Custom Components list for "Basic" or "Dhm" for example, depending on which Components you want to deploy.
Each of the available examples can be deployed to the same device as long as their Components have been previously registered.

Once the **Firmware** is created, we need to deploy it to your device. Click the **Deployment** button in the *Formware* section.

Name your deployment, select the previously created *Firmware*, and checkmark the Components that you want to deploy and choose their versions.
Select the devices that the Components should be deployed to.

Telemetry data should start appearing after several minutes, and you can start sending /IOTCONNECT Commands to the devices. 

# Developing Your Own Components

To learn more about AWS IoT Greengrass, visit the [AWS IoT Greengrass Documentation](https://docs.aws.amazon.com/greengrass/).

Aside from the Component [examples](examples), if you wish to  learn more about how to send telemetry or receive commands, refer to the
[/IOTCONNECT Python Lite SDK](https://github.com/avnet-iotconnect/iotc-python-sdk-lite) examples. The /IOTCONNECT Python Lite SDK client interface closely matches that of this /IOTCONNECT Greengrass SDK Client.

It is recommended that you get familiar with building and deploying the Basic Example before proceeding to create 
your own component.

Here are the minimal high level steps that can be followed when making your own Components based on the Basic Example. 
We will be using *my-component* as the Component directory and *com.mycompany.MyComponent* as the Component name: 
* Copy the basic-example code into a directory named *my-component*. *my-component* directory should contain recipe.yaml and other files.
* Specify your Component version in gdk-config.json.
* Specify your Component name in gdk-config.json, as well as the recipe.yaml as the prefix for the rules in the *accessControl* section. 
* The name of the directory determines the name of artifacts zip and the directory where the artifacts will be deployed.
Therefore, it is required to modify the lifecycle steps to refer to *my-component* instead of basic-example 
in the recipe.
* Replace the *basic-sample.zip* with *my-component.zip* as well in the S3 artifact **Uri** path in recipe.yaml.
* In your Python script that will be invoked by the *Run* Lifecycle step, ensure to:
  * Instantiate the Client with appropriate optional settings and callbacks object.
  * Implement the command callback if you want to be handling cloud-to-device commands.
  * Send your telemetry by invoking Client.send_telemetry()


# Development Tips

For best development turnaround, it is recommended to install a Greengrass Device (Nucleus)
on your development PC and use the ```local-deploy.sh``` to instantly deploy the Component locally.
This makes it possible to test your Component
without having to update the revision and upload it to /IOTCONNECT every time a change is made,
improving the overall development turnaround time.

After creating the PC greengrass device, make sure to also deploy ```aws.greengrass.Cli``` Public Component
(only on Nucleus Classic!)
using the /IOTCONNECT Firmware deployment option. The Greengrass CLI will be used 
in conjunction with ```local-deploy.sh``` to locally deploy your example.
When executing this script, pass the same parameters to it as you would to the ``build.sh``

If making changes to the SDK itself or needing to ship custom python packages, see the PACKAGE_LOCAL_SDK
behavior in ```build.sh```.

Once you have tested your Component or changes on a local Nucleus, the Component code 
should be easier to troubleshoot.

# Cleaning Up

If it is needed to remove greeenras-lite or if needing to re-run the GGLite installer again 
in order to use a diffeent device name,
the following commands are required to ensure that the installer can safely run again:

```bash
systemctl stop greengrass-lite.target
systemctl disable greengrass-lite.target
rm -rf /var/lib/greengrass
userdel ggcore
userdel gg_component
```

# Licensing

This python package is distributed under the [MIT License](LICENSE.md).
