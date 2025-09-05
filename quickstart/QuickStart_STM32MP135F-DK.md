# STM32MP135F-DK AWS IoT Greengrass nucleus lite QuickStart
<img src="https://github.com/avnet-iotconnect/iotc-python-greengrass-sdk/blob/main/quickstart/media/STM32MP135x-DK_w_gg.png" width="300" />  

1. [Introduction](#1-introduction)
2. [Requirements](#2-requirements)

   * [Hardware](#hardware)
   * [Software](#software)
3. [Hardware Setup](#3-hardware-setup)
4. [/IOTCONNECT: Cloud Account Setup](#4-iotconnect-cloud-account-setup)
5. [/IOTCONNECT: Import the Device Template](#5-iotconnect-import-the-device-template)
6. [/IOTCONNECT: Create the Greengrass Device](#6-iotconnect-create-the-greengrass-device)
7. [Download and Write the Image](#7-download-and-write-the-image)
8. [Configure the Device](#8-configure-the-device)

   * [Obtain the IP Address](#obtain-the-ip-address)
   * [Transfer the Device Information](#transfer-the-device-information)
   * [Run the Setup Script](#run-the-setup-script)
9. [Deploy the Greengrass Component](#9-deploy-the-greengrass-component)

   * [Load the Recipe](#load-the-recipe)
   * [Load the Artifact](#load-the-artifact)
   * [Create Package](#create-package)
   * [Deploy Package](#deploy-package)
10. [Import a Dynamic Dashboard](#10-import-a-dynamic-dashboard)
11. [Resources](#11-resources)

## 1. Introduction
This guide will walk through the steps to create and demonstrate a Device Health Monitoring application solution on the STM32MP135F-DK.  The solution utilizes the AWS Greengrass nucleus lite. Avnet's /IOTCONNECT platform will also be used to streamline all actions that would otherwise be performed in the AWS Console. The main tasks that will be performed are as follows:  

1. Create an /IOTCONNECT account
2. Import an example **Device Template** in /IOTCONNECT
3. Create a **Greengrass Device** in /IOTCONNECT
4. Setup **nucleus lite** on the target device
5. Download and Register a pre-built **Greengrass Component** in /IOTCONNECT
6. Create a **Deployment** package that defines the **Greengrass Components** deployed to the nucleus
7. Deploy the **Component** to the target device
8. View live data and interact with the target device using **Dynamic Dashboards** in /IOTCONNECT

## 2. Requirements
This guide has been written and tested to work on a Windows 10/11 PC to reach the widest audience.

### Hardware 
* STM32MP135F-DK [Purchase](https://www.avnet.com/shop/us/products/stmicroelectronics/stm32mp135f-dk-3074457345651659229/?srsltid=AfmBOopijKmQ00ko1YYwjONN5cRH9akfAf_aqdRSphwy7iE1XhpDUiG0) | [User Manual & Kit Contents](https://www.st.com/resource/en/user_manual/um2993-discovery-kit-with-1-ghz-stm32mp135fa-mpu-stmicroelectronics.pdf) | [All Resources](https://www.st.com/en/evaluation-tools/stm32mp135f-dk.html)
* 1 USB Type-C Cable
* 1 Micro-USB Cable
* Ethernet Cable

### Software
* A serial terminal such as [TeraTerm](https://github.com/TeraTermProject/teraterm/releases) or [PuTTY](https://www.putty.org/)
* Disk image writing software such as [BalenaEtcher](https://etcher.balena.io/)

## 3. Hardware Setup
Make the following connections using the image below as reference:
1. Connectivity: Connect an **Ethernet Cable** from your LAN (modem/router/switch) to the Ethernet connector labeled **#1**.
2. Power: Connect the **USB-C cable** from a 5V/2.4A power supply (could be your PC) to the PWR USB-C connector on the board, labeled **#2**.
3. Debug: Connect the Micro-USB cable from your PC to the Micro-USB connector labeled **#3** on the reference image.
See the reference image below for cable connections:  
<img src="./media/stm32mp135F-dk_board_setup.png" width="600">

## 4. /IOTCONNECT: Cloud Account Setup
An /IOTCONNECT account with an AWS backend is required.  If you need to create an account, a free trial subscription is available.
The free subscription may be obtained directly from [iotconnect.io](https://iotconnect.io) or through the AWS Marketplace.

* Option #1 (Recommended) /IOTCONNECT via [AWS Marketplace](https://github.com/avnet-iotconnect/avnet-iotconnect.github.io/blob/main/documentation/iotconnect/subscription/iotconnect_aws_marketplace.md) - 60 day trial; AWS account creation required
* Option #2 /IOTCONNECT via [iotconnect.io](https://subscription.iotconnect.io/subscribe?cloud=aws) - 30 day trial; no credit card required

> [!NOTE]
> Be sure to check any SPAM folder for the temporary password after registering.

## 5. /IOTCONNECT: Import the Device Template
1. Download the pre-made Device Template: [all-apps-device-template.json](../examples/common/files/all-apps-device-template.json)
2. Using the Sidebar menu in /IOTCONNECT, Navigate to *Device -> Greengrass Device -> Template (bottom menu)*.
<img width="1017" alt="click_templates" src="https://github.com/user-attachments/assets/e20ee569-38a1-4da6-bce1-08c66169774a" />

4. Click on the **Create Template** button and then the **Import** button and browse to select the device template .json file.
<img width="326" height="227" alt="click_create_template" src="https://github.com/user-attachments/assets/6c6c3e4d-49fb-4cef-83ef-4a9a46f7adeb" />

## 6. /IOTCONNECT: Create the Greengrass Device
1. At the bottom of the /IOTCONNECT GUI, click the **Devices**
<img width="1011" height="73" alt="click_devices" src="https://github.com/user-attachments/assets/fcea8f0c-f412-4ad2-a0c1-c172ca30ef1d" />

2. At the top-right, click **Create Device**
<img width="471" height="211" alt="click_create_device" src="https://github.com/user-attachments/assets/e57d01b4-bb59-43c1-a926-cf862195b071" />

3. Enter `STM32MP135Fdemo` for the **Unique ID** and **Device Name**  
4. Select the **Entity** to put the device in (For new accounts, there is only one option)  
5. Select `ggsdkdemo` for the **Template**  
6. Select `Nucleus Lite` for the **Device Type**
7. Click **Save & View**
<img width="1625" height="533" alt="enter_device_info" src="https://github.com/user-attachments/assets/da45e315-ff83-4f67-903a-38ff5c8dd5a6" />

8. Download the "Connection Kit" by clicking the icon in the upper right of the device page.  Save this file as `connectionKit.zip`.  This contains information about the device which will be used to configure the board in a future step.
<img width="380" height="180" alt="connection_kit" src="https://github.com/user-attachments/assets/ab693911-aebe-4916-b85d-9d734d067a46" />

## 7. Download and Write the Image
Avnet has created a pre-built image for the STM32MP135F-DK which can be directly written to the SD card provided with the board.
>[!NOTE]
> The image provided below is based on the ST StarterPackage version v6.0.0 for the STM32MP13 series. Please review [Section 6 of the ST StarterPackage Guide](https://wiki.st.com/stm32mpu/wiki/STM32MP13_Discovery_kits_-_Starter_Package) for more information on the binaries compatible with this development board.
1. Download and unzip the image :  [stm32mp135f-dk-sdcard-6.6-yocto-scarthgap-mpu-v24.11.06.zip](https://downloads.iotconnect.io/partners/st/disk-images/stm32mp135f-dk/stm32mp135f-dk-sdcard-6.6-yocto-scarthgap-mpu-v24.11.06.zip)  
2. Open Balena Etcher and Write the Image to the SD card
3. Ensure the Boot Switches are set as follows:  
   * BOOT0 = ON
   * BOOT1 = OFF
   * BOOT2 = ON
   * BOOT3 = ON or OFF (switch is not connected to PCB)  
![img](media/STM32MP135x-DKx_boot_switches_microSD_card.png)
4. Insert the SD card into the board and power it on

## 8. Configure the Device
Configuration of the device is mostly automated by using a device setup script, but first the device information bundle needs to be transferred to the board.
The steps required are as follows:
1. Obtain the IP address of the board
2. Transfer the device information to the board
3. Run the setup script

### Obtain the IP Address
* Connect to the board using a serial terminal, such as TeraTerm, and use the command `ifconfig`
* The IP Address will listed next to the interface `end0`
* Leave the serial terminal window open for a future step

### Transfer the Device Information
* Navigate to the directory where the Connection Kit ("connectionKit.zip") was saved.
* **Right-Click** and select **Open in Terminal**
* Copy/Paste the following command replacing x.x.x.x with the IP address of the board
```commandline
scp connectionKit.zip root@x.x.x.x:
```

### Run the Setup Script
* Return to the TeraTerm window.
* Copy/Paste the following command to download the setup script and execute it.
```commandline
wget https://raw.githubusercontent.com/avnet-iotconnect/iotc-python-greengrass-sdk/refs/heads/main/installer/openstlinux/device-setup.sh -O device-setup.sh
```

* Once the script has completed, use the following command to configure the device information:
```bash
bash device-setup.sh ~/connectionKit.zip
```
> [!NOTE]
> This script will set up the development environment and precompile Python packages and may take around 7 minutes.

* **REBOOT the Board**

## 9. Deploy the Greengrass Component
To deploy the pre-built component, we'll use /IOTCONNECT to create a deployment package that contains the artifact file and a recipe.
* **Download** and **Extract** the *Device Health Monitoring Component*: [iotc-gg-component-dhm-demo-1.0.0.zip](https://downloads.iotconnect.io/greengrass/components/iotc-gg-component-dhm-demo-1.0.0.zip)

### Load the Recipe
1. In the /IOTCONNECT platform, click **Package** at the bottom of the screen, then click **Components** at the top.
<img width="1015" height="84" alt="click_package" src="https://github.com/user-attachments/assets/da800a4d-f5cf-4cd6-9438-ccefb5056501" />
<img width="570" height="211" alt="click_components" src="https://github.com/user-attachments/assets/1ea5ae9d-c9e7-4abd-815b-6e4e6572a0d1" />

2. In the "Create Component" box, browse for the recipe file ("recipe.yaml") from the previously extracted component archive here:  `<your working directory>\iotc-gg-component-dhm-demo-1.0.0\dhm-demo\greengrass-build\recipes\recipe.yaml`

### Load the Artifact 
1. Click the icon to the right of "dhm-demo.zip" and navigate to the dhm-demo.zip from the previously extracted archive here: `<your working directory>\iotc-gg-component-dhm-demo-1.0.0\dhm-demo\greengrass-build\artifacts\io.iotconnect.example.IotConnectSdkDhmDemo\1.0.0\dhm-demo.zip`
2. Click **Save**

### Create Package
1. Return to the **Package** tab and then, at the top-right, click **Package**
<img width="390" height="167" alt="create_package" src="https://github.com/user-attachments/assets/ac41c5ae-0d45-444b-8357-72d1c41f01e6" />

2. Enter a *Name* such as `MyDHMdemo`
3. Select the `ggsdkdemo` Template
4. Select the **Custom Component** in the drop-down

5. Click **Save**

### Deploy Package
1. **Click** **Deploy**
<img width="567" height="155" alt="click_deploy" src="https://github.com/user-attachments/assets/1b321aa8-9351-4b3d-b841-dfc12c91233f" />

2. Add a *Name* and select each item in the drop-downs (there will only be one option for each)
3. Ensure you tick the box under "Components" and pick the version `1.0.0`
4. **Click** *Deploy*
<img width="1457" height="440" alt="deploy_overview" src="https://github.com/user-attachments/assets/71122dc5-7315-4cfd-a9dc-e174a00edb0a" />

The package with the component is now being deployed to the device.

This process can take 5min or more, so wait until you see "Success" in the Deployment History.

## 10. Import a Dynamic Dashboard
/IOTCONNECT Dynamic Dashboards are an easy way to visualize data and interact with edge devices.  
* Download the *Device Health Monitoring* dashboard: [greengrass_nucleus_lite_STM32MP135F_dashboard.json](greengrass_nucleus_lite_STM32MP135F_dashboard.json)

* Switch back to the /IOTCONNECT browser window and verify the device status is displaying as `Connected`
* **Click** `Create Dashboard` from the top of the page
* **Select** the `Import Dashboard` option and **Click** *Browse* to select the dashboard template previously downloaded.
* **Select** the *Template* ("ggsdkdemo") and your *Device Name*
* **Enter** a name (such as `My STM32MP135 Greengrass Dashboard`) and **Click** *Save* the finalize the import

You will now be in the dashboard edit mode. You can add/remove widgets or just click `Save` in the upper-right corner to exit the edit mode.
<img width="=800" alt="dashboard_overview" src="https://github.com/user-attachments/assets/5141fb05-73c4-4166-9148-65820c0da7e6" />

## 11. Resources
* Try out the other available [greengrass lite components](https://github.com/avnet-iotconnect/iotc-python-greengrass-sdk/tree/main/examples)
* Learn more and develop your own components: [iotc-python-greengrass-sdk](https://github.com/avnet-iotconnect/iotc-python-greengrass-sdk)
* [Purchase the STM32MP135F-DK](https://www.avnet.com/shop/us/products/stmicroelectronics/stm32mp135f-dk-3074457345659849803/?srsltid=AfmBOopquBKia0rOHMSNs21TNvnk7RXm224OmsFITHs0A9LhuKjX4zHK)
* [More /IOTCONNECT ST Guides](https://avnet-iotconnect.github.io/partners/st/)
* [/IOTCONNECT Overview](https://www.iotconnect.io/)
* [/IOTCONNECT Knowledgebase](https://help.iotconnect.io/)
