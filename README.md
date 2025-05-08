# Introduction
This project is the Avnet /IOTCONNECT AWS Greengrass SDK intended for 
the /IOTCONNECT platform Greengrass devices and Components based on Python.

The project based on the 
[/IOTCONNECT Python Library](https://github.com/avnet-iotconnect/iotc-python-lib).

While the example Components and the SDK can be built on other OS-es, 
only Linux is supported for guides, along with the provided build scripts.

# Licensing

This python package is distributed under the [MIT License](LICENSE.md).

# Installing the Greengrass Nucleus

The Components using this SDK need to be run on a Greengrass Nucleus. 

If testing our [examples](examples), see the README in that directory on how to set up the Device Remplate etc.

When creating an /IOTCONNECT Greengrass Device (Nucleus)
using the /IOTCONNECT Web UI:
* If using the Classic Nucleus, execute the script provided by the website and the follow the online instructions.
* If using the Nucleus Lite on Embedded Linux devices, download the device credential package to the device
and follow the device-specific instructions provided in the [doc](doc) directory.

Once your Greengrass Device Nucleus is running, you can proceed to develop and deploy 
your greengrass Component using this repository.

# Building and Running The Examples

For a reference implementation, see [examples/iotc-basic-demo](examples/iotc-basic-demo).

To set up a Component package and recipe, first execute the [build.sh](examples/iotc-basic-demo/build.sh)
script in the selected corresponding example.

There are two ways to build the example Components:
* With your CPID and Environment specified.
* With default configuration.

It is recommended to use the first option, and before building or deploying specify:

```shell
export IOTC_ENV=YourENV
export IOTC_CPID=YourCPID
```

These values can be obtained from **Settings -> Key Vault** on the /IOTCONNECT Web UI. 

At this point in time, it is not strictly necessary to provide these configuration values, and the SDK 
will use the information provided by the Greengrass environment to guess the MQTT topics that 
will be used to communicate to /IOTCONNECT, but in the future, 
more advanced SDK features may require this.

The build script will install **gdk** locally and build your Component such that 
the provided CPID and Environment values will be injected into the recipe.yaml.

# Deploying Your Components

This guide will summarize some of the steps to deploy your Components with /IOTCONNECT, 
but for more details and a guide with screenshots, please refer to the 
[/IOTCONNECT Greengrass Quickstart](https://docs.iotconnect.io/iotconnect/quick-start/greengrass-device/).


Once your Component is built, you can upload the zip package it along with the generated recipe from the
```greengrass-build``` directory of the Component. Do **NOT** use the ```recipe.yaml``` from
the root directory of the example as that recipe will need to be processes.

You can find all these Web UI pages in the *Firmware* (bottom of the screen) section of the *Device -> Greengrass Device* 
section from the sidebar menu, with buttons at the top of the screen. 


Click the **Components** button in the *Firmware* section and either to register a new Component by following the steps below, 
OR locate your existing component and *Upgrade* it by clicking the **Upgrade** button 
on the right side of the component entry.

A few extra steps required before uploading your component:
- Rename your built component zip in the greengrass-build directory to contain a unique version number. 
For example, rename iotc-basic-demo.zip to iotc-basic-demo-0.1.0.zip.
- Once you upload your component, use the copy button on the right side panel with the files list 
and apply it to the recipe.yaml URI section located in the greengrass-build directory. For example:

```yaml
...
Manifests:
- Platform:
    os: linux
    runtime: '*'
  Artifacts:
  - Uri: s3://root-1233456/123456789-2854-4a77-8f3b-ca1696401e08/gg-artifacts/iotc-basic-demo-0.1.0.zip
    Unarchive: ZIP
  Lifecycle:
...
```

- Upload the modified recipe and create the Component by clicking tge *Save* button.

Once the Components are registered with /IOTCONNECT, you need to click the **Create Firmware** button in the *Firmware* section.

Name your Firmware, select your previously created device template and set of Components that you want to deploy.
You can search the Custom Components list for "Basic" or "Dhm" for example, depending on which Components you want to deploy.
All of the available examples can be deployed to the same device as long as their Components have been previously registered.

Once the **Firmware** is created, we need to deploy it to your device. Click the **Deployment** button in the *Formware* section.

Name your deployment, select the previously created *Firmware*, and checkmark the components that you want to deploy and choose their versions.
Select the devices that the components should be deployed.

Telemetry data should start appearing after several minutes, and you can start sending /IOTCONNECT Commands to the devices. 

# Developing Your Own Components

To learn more about how to send telemetry, or receive commands, refer to the
[/IOTCONNECT Python Lite SDK](https://github.com/avnet-iotconnect/iotc-python-sdk-lite) examples
as the client interface closely matches that of the SDK.

# Development Tips

For best development turnaround, it is recommended to install a Greengrass Device (Nucleus)
on your development PC and use the ```local-deploy.sh``` to instantly deploy the component locally.
This makes it possible to test your component
without having to update the revision and upload it to /IOTCONNECT every time a change is made,
improving the overall development turnaround time.

After creating the PC greengrass device, make sure to also deploy ```aws.greengrass.Cli``` Public Component
using the /IOTCONNECT Firmware deployment option. The Greengrass CLI will be used 
in conjunction with ```local-deploy.sh``` to locally deploy your example.
When executing this script, pass the same parameters to it as you would to the ``build.sh``

If making changes to the SDK itself or needing to ship custom python packages, see the PACKAGE_LOCAL_SDK
behavior in ```build.sh```.

Once you have tested your Component or changes on a local nucleus, the Component code 
should be easier troubleshoot.

# Licensing

This python package is distributed under the MIT License.
