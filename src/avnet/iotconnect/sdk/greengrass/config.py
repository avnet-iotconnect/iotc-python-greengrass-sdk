# SPDX-License-Identifier: MIT
# Copyright (C) 2024 Avnet
# Authors: Nikola Markovic <nikola.markovic@avnet.com> et al.

import os.path

from avnet.iotconnect.sdk.sdklib.config import DeviceProperties
from avnet.iotconnect.sdk.sdklib.error import DeviceConfigError
from awsiot.greengrasscoreipc.clientv2 import GreengrassCoreIPCClientV2
from awsiot.greengrasscoreipc.model import ServiceError, UnauthorizedError, ResourceNotFoundError


class DeviceConfig:

    def __init__(self, env: str, cpid: str):
        """
        IoTConnect parameters required to perform discovery.

        It is possible to extract these parameters from component configuration
        with from_component_configuration()

        :param env: Your account environment. You can locate this in you IoTConnect web UI at Settings -> Key Value
        :param cpid: Your account CPID (Company ID). You can locate this in you IoTConnect web UI at Settings -> Key Value
        """
        self.env = env
        self.cpid = cpid

    def to_properties(self) -> DeviceProperties:
        thing_name = os.getenv("AWS_IOT_THING_NAME")
        duid = thing_name.removeprefix(self.cpid + "-")

        properties = DeviceProperties(
            duid=duid,
            cpid=self.cpid,
            env=self.env,
            platform="aws"
        )
        properties.validate()
        return properties

    @classmethod
    def from_component_configuration(cls, ipc_client: GreengrassCoreIPCClientV2) -> 'DeviceConfig':
        """ Return a class instance based on a downloaded iotcDeviceConfig.json fom device's Info panel in /IOTCONNECT"""
        try:
            response = ipc_client.get_configuration()
            config = response.value
            return DeviceConfig(
                cpid=config.get("IOTC_CPID"),
                env=config.get("IOTC_ENV")
            )
        except (ServiceError, UnauthorizedError, ResourceNotFoundError) as e:
            raise DeviceConfigError("Failed to retrieve component configuration from Greengrass. Check connectivity and permissions.") from e
