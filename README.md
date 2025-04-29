# Introduction
This project is the Avnet /IOTCONNECT AWS Greengrass SDK intended for 
the /IOTCONNECT platform Greengrass devices and Components based on Python.

The project based on the 
[/IOTCONNECT Python Library](https://github.com/avnet-iotconnect/iotc-python-lib).

While the example Components and the SDK can be built on other OS-es, 
only Linux is supported for development, along with the provided build scripts.

# Licensing

This python package is distributed under the [MIT License](LICENSE.md).

# Installing the Greengrass Nucleus

The Components using this SDK need to be run on a Greengrass Nucleus. 

When creating an /IOTCONNECT Greengrass Device (Nucleus)
using the /IOTCONNECT Web UI:
* If using the Classic Nucleus, execute the script provided by the website and the follow the online instructions.
* If using the Nucleus Lite on Embedded Linux devices, download the device credential package to the device
and follow the device-specific instructions provided in the [doc](doc) directory.

Once your Greengrass Device Nucleus is running, you can proceed to develop and deploy 
your greengrass Component using this repository.

# Building and Running The Examples

For a reference implementation, see [examples/iotconnect-gg-basic-demo](examples/iotconnect-gg-basic-demo).

To set up a Component package and recipe, first execute the [build.sh](examples/iotconnect-gg-basic-demo/build.sh)
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

At this point in time, it is not strictly necessary to provide these values, and the SDK 
will use the information provided by the Greengrass environment to guess the MQTT topics that 
will be used to communicate to /IOTCONNECT, but in the future, 
more advanced SDK features may require this.

The build script should install **gdk** locally and build your Component such that 
the provided CPID and Environment values will be injected into the recipe.yaml.

Once your Component is built, you can upload the zip package it along with the generated recipe from the
```greengrass-build``` directory of the Component. Do **NOT** use the ```recipe.yaml``` from
the root directory of the example as that recipe will need to be processes.

# Developing Your Components

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
