# SPDX-License-Identifier: MIT
# Copyright (C) 2024 Avnet
# Authors: Nikola Markovic <nikola.markovic@avnet.com> et al.

import os.path
from typing import Optional

from avnet.iotconnect.sdk.sdklib.config import DeviceProperties
from avnet.iotconnect.sdk.sdklib.error import DeviceConfigError
from awsiot.greengrasscoreipc.clientv2 import GreengrassCoreIPCClientV2
from awsiot.greengrasscoreipc.model import ServiceError, UnauthorizedError, ResourceNotFoundError


class DeviceConfig:

    def __init__(self, env : Optional[str] = None, cpid: Optional[str] = None, duid: Optional[str] = None):
        """
        IoTConnect parameters required to perform discovery and obtain device identity.

        DeviceConfig is optional to the Client, but some features may depend on DeviceConfig
        being passed to the client. If DeviceConfig is not passed to the client,
        the client will infer topics from Thing Name and proceed. In this mode
        standard features (telemetry, commands and OTA) will be available.

        It is possible to extract these parameters from component configuration
        with from_component_configuration() if the component contains IOTC_CPID and IOTC_ENV
        and/or IOTC_DUID component parameters.

        :param env: Your account environment. You can locate this in you IoTConnect web UI at Settings -> Key Value
        :param cpid: Your account CPID (Company ID). You can locate this in you IoTConnect web UI at Settings -> Key Value
        :param duid: (Optional) Your Greengrass Device Unique ID (DUID).
            If duid id not provided, we will try to infer it from AWS Thing Name under which the device/Nucleus is running.
        """
        self.env = env
        self.cpid = cpid
        self.duid = duid

    """
    Attempts to convert the device configuration into DeviceProperties
    that can be used to obtain device identity via HTTP discovery/identity calls (Device REST API).     
    """
    def to_properties(self) -> Optional[DeviceProperties]:
        if self.duid is None and self.cpid is not None:
            thing_name = os.getenv("AWS_IOT_THING_NAME")
            self.duid = thing_name.removeprefix(self.cpid + "-")
        properties = DeviceProperties(
            duid=self.duid,
            cpid=self.cpid,
            env=self.env,
            platform="aws"
        )
        try:
            properties.validate()
            return properties
        except DeviceConfigError:
            return None

    @classmethod
    def from_component_configuration(cls, ipc_client: GreengrassCoreIPCClientV2) -> 'DeviceConfig':
        """ Return a class instance based on a downloaded iotcDeviceConfig.json fom device's Info panel in /IOTCONNECT"""
        try:
            response = ipc_client.get_configuration()
            config = response.value
            env=config.get("IOTC_ENV")
            cpid=config.get("IOTC_CPID")
            duid=config.get("IOTC_DUID")

            if env is not None and len(env) == 0:
                env = None
            if cpid is not None and len(cpid) == 0:
                cpid = None
            if duid is not None and len(duid) == 0:
                duid = None

            if duid is None and cpid is not None and env is not None:
                # infer DUID
                thing_name = os.getenv("AWS_IOT_THING_NAME")
                duid = thing_name.removeprefix(cpid + "-")

            return DeviceConfig(
                env=env,
                cpid=cpid,
                duid=duid
            )
        except (ServiceError, UnauthorizedError, ResourceNotFoundError) as e:
            raise DeviceConfigError("Failed to retrieve component configuration from Greengrass. Check connectivity and permissions.") from e
