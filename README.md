# Introduction
This project is the Avnet /IOTCONNECT AWS Greengrass SDK intended for 
the /IOTCONNECT platform Greengrass devices and components based on Python.

The project based on the 
[/IOTCONNECT Python Library](https://github.com/avnet-iotconnect/iotc-python-lib).

# Installing the Greengrass Nucleus

This greengrass needs to be run on a Nucleus. When creating an /IOTCONNECT Greengrass Device (Nucleus)
using the /IOTCONNECT Web UI, execute the script provided and the follow the online instructions.

Once your Greengrass Device (Nucleus) is created, you can proceed to develop and deploy 
your greengrass component using this repository.

# Reference Implementation

For a reference implementation, see [examples/iotconnect-gg-basic-demo](examples/iotconnect-gg-basic-demo).

To use the reference implementation, develop on Linux for best experience.

To set up a component package and recipe, first execute the [build.sh](examples/iotconnect-gg-basic-demo) script from the
component directory by passing your account CPID as the first argument to the script
and your account environment as the second argument. For example:

```shell
./examples/iotconnect-gg-basic-demo/build.sh MCPID MYENV
```

Both of these parameter values can be obtained from your account *Settings->Key Vault* page.

The build script should install gdk locally and build your component such that 
the provided CPID and Environment values will be injected into the recipe.yaml.

Once your component is built, you can upload the zip package it along with the generated recipe from the
```greengrass-build``` directory of the component. Do **NOT** use the ```recipe.yaml``` from
the root directory of the example as that recipe will need to be processes.


To learn more about how to send telemetry, or receive commands, refer to the
[/IOTCONNECT Python Lite SDK](https://github.com/avnet-iotconnect/iotc-python-sdk-lite) examples
as the client interface closely matches that of the SDK.


# Development Tips

For best development turnaround, it is recommended to install a Greengrass Device (Nucleus)
on your development PC and use the ```local-deploy.sh``` to instantly deploy the component locally
without having to update the revision and upload it to /IOTCONNECT every time a change is made.

After creating the PC greengrass device, make sure to also deploy ```aws.greengrass.Cli``` Public Component
using the /IOTCONNECT Firmware deployment option. The Greengrass CLI will be used 
in conjunction with ```local-deploy.sh``` to locally deploy your example.
When executing this script, pass the same parameters to it as you would to the ``build.sh``

If making changes to the SDK itself or needing to ship custom python packages, see the PACKAGE_LOCAL_SDK
behavior in the build.sh.

# Licensing
This python package is distributed under the MIT License.
