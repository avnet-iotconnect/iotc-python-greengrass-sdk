# SPDX-License-Identifier: MIT
# Copyright (C) 2024 Avnet
# Authors: Nikola Markovic <nikola.markovic@avnet.com> et al.
import os
from datetime import datetime, timezone
from typing import Callable, Optional

from avnet.iotconnect.sdk.sdklib.dra import DeviceRestApi
from avnet.iotconnect.sdk.sdklib.error import C2DDecodeError, ClientError, DeviceConfigError
from avnet.iotconnect.sdk.sdklib.mqtt import C2dOta, C2dMessage, C2dCommand, C2dAck, TelemetryRecord, TelemetryValueType, encode_telemetry_records, encode_c2d_ack, decode_c2d_message
from avnet.iotconnect.sdk.sdklib.protocol.identity import ProtocolTopicsJson
from awsiot.greengrasscoreipc.client import SubscribeToIoTCoreStreamHandler
from awsiot.greengrasscoreipc.clientv2 import GreengrassCoreIPCClientV2
from awsiot.greengrasscoreipc.model import UnauthorizedError, ResourceNotFoundError, ServiceError, SubscriptionResponseMessage, QOS, IoTCoreMessage

from .config import DeviceConfig


class Callbacks:
    def __init__(
            self,
            command_cb: Optional[Callable[[C2dCommand], None]] = None,
            ota_cb: Optional[Callable[[C2dOta], None]] = None,
            generic_message_callbacks: dict[int, Callable[[C2dMessage, dict], None]] = None
    ):
        """
        Specify callbacks for C2D command, OTA (not implemented yet) or MQTT disconnection.

        :param command_cb: Callback function with first parameter being C2dCommand object.
            Use this callback to process commands sent by the back end.

        :param ota_cb: Callback function with first parameter being C2dOta object.
            Use this callback to process OTA updates sent by the back end.

        :param generic_message_callbacks: A dictionary of callbacks indexed by the message type.
        """

        self.command_cb = command_cb
        self.ota_cb = ota_cb
        self.generic_message_callbacks = generic_message_callbacks or dict[int, C2dMessage]()  # empty dict otherwise


class ClientSettings:
    """ Optional settings that the user can use to control the client MQTT connection behavior"""

    def __init__(
            self,
            verbose: bool = True
    ):
        if verbose:
            from . import __version__ as SDK_VERSION
            from avnet.iotconnect.sdk.sdklib import __version__ as LIB_VERSION
            print(f"/IOTCONNENCT Greengrass Client started with version {SDK_VERSION} and Lib version {LIB_VERSION}")
        self.verbose = verbose


class Client:

    def __init__(
            self,
            callbacks: Callbacks = None,
            settings: ClientSettings = None,
            config: DeviceConfig = None
    ):
        """
        Avnet /IOTCONNECT Greengrass client that provides an easy way for the user to
        connect integrate their Greengrass components with /IOTCONNECT, send and receive data.

        Usage - See basic-demo example at https://github.com/avnet-iotconnect/iotc-python-greengrass-sdk for more details:

        - Construct this client class:

            - (Optional) provide callbacks for C2D Commands or device disconnect.
                See the basic-example.py at https://github.com/avnet-iotconnect/iotc-python-lite-sdk example for details.

            - (Optional) provide ClientSettings to tune the client behavior.

            - (Optional) provide DeviceConfig to enhance this client's features.


        - Send messages with Client.send_telemetry() or send_telemetry_records().
            See the basic-demo example at https://github.com/avnet-iotconnect/iotc-python-lite-sdk for more info.
            For example:
                c.send_telemetry({
                    'temperature': get_sensor_temperature()
                })

        - Receive Command or OTA callbacks and send command and OTA ACKs with send_command_ack()

        :param callbacks: (Optional)
            User callbacks for Command and OTA messages.
            See Callbacks class.
        :param settings: (Optional)
            Settings that can be used to better control this client behavior.
            See ClientSettings class.
        :param config: (Optional)
            The user can provide their CPID and environment. If provided,
            the future implementation may or may not enable additional features
            as the information that we can obtain without these parameters is limited.
        """
        self.user_callbacks = callbacks or Callbacks()
        self.settings = settings or ClientSettings()

        self.user_callbacks = callbacks or Callbacks()

        self.ipc_client = GreengrassCoreIPCClientV2()

        self.stream_handler = Client.SubscribeStreamHandler(self)

        # get what we can from component config
        if config is None:
            config = DeviceConfig.from_component_configuration(self.ipc_client)

        self.topics = None

        device_properties=config.to_properties()
        if device_properties is not None:
            try:
                # Will likely raise DeviceConfigError as most likely the component comfig will be default with all nulls.

                self.topics = DeviceRestApi(device_properties, verbose=self.settings.verbose).get_identity_data().topics
                if self.settings.verbose:
                    print("Successfully obtained device identity.")
            except DeviceConfigError:
                pass

        if self.topics is None:
            # User did not configure the device.
            # Fall back to fixed topics from Thing Name.
            self.topics = Client._mqtt_topics_from_greengrass_env()
            if self.settings.verbose:
                print("CPID and ENV are not configured. Used AWS_IOT_THING_NAME to determine the publish topics.")

        try:
            self.ipc_client.subscribe_to_iot_core(
                topic_name=self.topics.c2d,
                qos=QOS.AT_LEAST_ONCE,
                stream_handler=self.stream_handler
            )
        except (ServiceError, UnauthorizedError, ResourceNotFoundError) as e:
            raise ClientError(
                "Failed to subscribe to C2D topic: Greengrass is either not connected, lacks permission, or encountered an internal error."
            ) from e


    @classmethod
    def timestamp_now(cls) -> datetime:
        """ Returns the UTC timestamp that can be used to stamp telemetry records """
        return datetime.now(timezone.utc)

    def send_telemetry(self, values: dict[str, TelemetryValueType], timestamp: datetime = None) -> None:
        """ Sends a single telemetry dataset. 
        If you need gateway/child functionality or need to send multiple value sets in one packet, 
        use the send_telemetry_records() method.
         
        :param TelemetryValues values:
            The name-value telemetry pairs to send. Each value can be
                - a primitive value: Maps directly to a JSON string, number or boolean
                - None: Maps to JSON null,
                - Tuple[float, float]: Used to send a lat/long geographic coordinate as decimal degrees as an
                    array of two (positive or negative) floats.
                    For example, [44.787197, 20.457273] is the geo coordinate Belgrade in Serbia,
                    where latitude 44.787197 is a positive number indicating degrees north,
                    and longitude a positive number as well, indicating degrees east.
                    Maps to JSON array of two elements.
                - Another hash with possible values above when sending an object. Maps to JSON object.
            in case when an object needs to be sent.
        :param datetime timestamp: (Optional) The timestamp corresponding to this dataset.
            If not provided, this will save bandwidth, as no timestamp will not be sent over MQTT.
             The server receipt timestamp will be applied to the telemetry values in this telemetry record.
             Supply this value (using Client.timestamp()) if you need more control over timestamps.
        """
        self.send_telemetry_records([TelemetryRecord(
            values=values,
            timestamp=timestamp
        )])

    def send_telemetry_records(self, records: list[TelemetryRecord]) -> None:
        """
        A complex, but more powerful way to send telemetry.
        It allows the user to send multiple sets of telemetry values
        and control the timestamp of each telemetry value set.
        Supports gateway devices with gateway-child relationship by allowing
        the user to set the parent/child unique_id ("id" in JSON)
        and tag of respective parent./child ("tg" in JSON)

        See https://docs.iotconnect.io/iotconnect/sdk/message-protocol/device-message-2-1/d2c-messages/#Device for more information.
        """

        packet = encode_telemetry_records(records)
        try:
            if self.settings.verbose:
                print(">", packet, self.topics.rpt)
            self.ipc_client.publish_to_iot_core(
                topic_name=self.topics.rpt,
                qos=QOS.AT_LEAST_ONCE,
                payload=bytes(packet, 'utf-8')
            )
        except (ServiceError, UnauthorizedError, ResourceNotFoundError) as e:
            raise ClientError(
                "Failed to publish: Greengrass is either not connected, lacks permission, or encountered an internal error."
            ) from e

    def send_command_ack(self, original_message: C2dCommand, status: int, message_str=None) -> None:
        """
        Send Command acknowledgement.

        :param original_message: The original message that was received in the callback.
        :param status: C2dAck.CMD_FAILED or C2dAck.CMD_SUCCESS_WITH_ACK.
        :param message_str: (Optional) For example: 'LED color now "blue"', or 'LED color "red" not supported'
        """

        if original_message.type != C2dMessage.COMMAND:
            print('Error: Called send_command_ack(), but message is not a command!')
            return
        self.send_ack(
            ack_id=original_message.ack_id,
            message_type=original_message.type,
            status=status,
            message_str=message_str,
            original_command=original_message.command_name
        )

    def send_ota_ack(self, original_message: C2dOta, status: int, message_str=None):
        """
        Send OTA acknowledgement.
        See the C2dAck comments for best practices with OTA download ACks.

        :param original_message: The original message that was received in the callback.
        :param status: For example: C2dAck.OTA_DOWNLOAD_FAILED.
        :param message_str: (Optional) For example: "Failed to unzip the OTA package".
        :param message_str: (Optional) For example: "Failed to unzip the OTA package".
        """
        if original_message.type != C2dMessage.OTA:
            print('Error: Called send_ota_ack(), but message is not an OTA request!')
            return
        self.send_ack(
            ack_id=original_message.ack_id,
            message_type=original_message.type,
            status=status,
            message_str=message_str
        )

    def send_ack(self, ack_id: str, message_type: int, status: int, message_str: str = None, original_command: str = None) -> None:
        """
        Send Command or OTA ack while having only ACK ID

        :param ack_id: Recorded ack_id from the original message.
        :param message_type: For example: C2dMessage.COMMAND or C2dMessage.OTA, .
        :param status: For example: C2dAck.CMD_FAILED or C2dAck.OTA_DOWNLOAD_DONE for command/OTA respectively.
        :param message_str: (Optional) For example: "Failed to unzip the OTA package", or 'LED color "red" not supported'
        :param original_command: (Optional) If this argument is passed,
            this command name will be printed along with any potential error messages.

        While the client should generally use send_ota_ack or send_command_ack, this method can be used in cases
        where the context of the original received message is not available (after OTA restart for example)
        """
        if ack_id is None or len(ack_id) == 0:
            if original_command is not None:
                print('Error: Message ACK ID missing. Ensure to set "Acknowledgement Required" in the template for command %s!' % original_command)
            else:
                print('Error: Message ACK ID missing. Ensure to set "Acknowledgement Required" in the template the command!' % original_command)
            return
        elif message_type not in (C2dMessage.COMMAND, C2dMessage.OTA):
            print('Warning: Message type %d does not appear to be a valid message type!' % message_type)  # let it pass, just in case we can still somehow send different kind of ack
        elif message_type == C2dMessage.COMMAND and not C2dAck.is_valid_cmd_status(status):
            print('Warning: Status %d does not appear to be a valid command ACK status!' % status)  # let it pass, just in case there is a new status
        elif message_type == C2dMessage.OTA and not C2dAck.is_valid_ota_status(status):
            print('Warning: Status %d does not appear to be a valid OTA ACK status!' % status)  # let it pass, just in case there is a new status

        packet = encode_c2d_ack(ack_id, message_type, status, message_str)

        try:
            self.ipc_client.publish_to_iot_core(
                topic_name=self.topics.ack,
                qos=QOS.AT_LEAST_ONCE,
                payload=bytes(packet, 'utf-8')
            )
        except (ServiceError, UnauthorizedError, ResourceNotFoundError) as e:
            raise ClientError(
                "Failed to publish: Greengrass is either not connected, lacks permission, or encountered an internal error."
            ) from e

    def _process_c2d_message(self, topic: str, payload: str) -> bool:
        # topic is ignored for now as we only subscribe to one
        # we ought to change this once we start supporting Properties (Twin/Shadow)
        try:
            # use the simplest form of ProtocolC2dMessageJson when deserializing first and
            # convert message to appropriate json later

            decoding_result = decode_c2d_message(payload)
            generic_message = decoding_result.generic_message

            if decoding_result.command is not None:
                if self.user_callbacks.command_cb is not None:
                    self.user_callbacks.command_cb(decoding_result.command)
                else:
                    if self.settings.verbose:
                        print("WARN: Unhandled command %s received!" % decoding_result.command.command_name)
                return True
            elif decoding_result.ota is not None:
                if self.user_callbacks.ota_cb is not None:
                    self.user_callbacks.ota_cb(decoding_result.ota)
                else:
                    if self.settings.verbose:
                        print("WARN: Unhandled OTA request received!")
                return True
            # else - generic message
            elif generic_message.is_fatal:
                if self.settings.verbose:
                    print("Received C2D message %s from backend. Device should stop operation." % generic_message.type_description)
            elif generic_message.needs_refresh:
                if self.settings.verbose:
                    print("Received C2D message %s from backend. Device should re-initialize the application." % generic_message.type_description)
            elif generic_message.heartbeat_operation is not None:
                if self.settings.verbose:
                    operation_str = "start" if generic_message.heartbeat_operation == True else "stop"
                    print("Received C2D message %s from backend. Device should %s heartbeat messages." % (generic_message.type_description, operation_str))
            else:
                if self.settings.verbose:
                    print("C2D Message parsing for message type %d is not supported by this client. Message was: %s" % (generic_message.ct, payload))

            # fallthrough for generic message handling
            generic_cb = self.user_callbacks.generic_message_callbacks.get(generic_message.type)
            if generic_cb is not None:
                generic_cb(generic_message, decoding_result.raw_message)
            return True

        except C2DDecodeError:
            print('C2D Parsing Error: "%s"' % payload)
            return False

    class SubscribeStreamHandler(SubscribeToIoTCoreStreamHandler):
        def __init__(self, this_client: "Client"):
            self.client = this_client

        def on_stream_event(self, event: IoTCoreMessage) -> None:
            payload = event.message.payload.decode('utf-8')
            if self.client.settings.verbose:
                print("<", payload)
            self.client._process_c2d_message(event.message.topic_name, payload)

        def on_stream_error(self, error: Exception) -> bool:
            if self.client.settings.verbose:
                print(f"STREAM ERROR: ", error)
            return True

        def on_stream_closed(self) -> None:
            """
            Invoked when the stream for this operation is closed.
            """
            pass

    # Fallback method if component is not configured.
    # We cannot infer other information
    @classmethod
    def _mqtt_topics_from_greengrass_env(cls) -> ProtocolTopicsJson:
        thing_name = os.getenv("AWS_IOT_THING_NAME")
        topics = ProtocolTopicsJson()
        topics.c2d = f'iot/{thing_name}/cmd'
        topics.rpt = f'$aws/rules/msg_d2c_rpt/{thing_name}/2.1/0'
        topics.di = f'$aws/rules/msg_d2c_di/{thing_name}/2.1/1'
        topics.flt = f'$aws/rules/msg_d2c_flt/{thing_name}/2.1/3'
        topics.od = f'$aws/rules/msg_d2c_od/{thing_name}/2.1/4'
        topics.hb = f'$aws/rules/msg_d2c_hb/{thing_name}/2.1/5'
        topics.ack = f'$aws/rules/msg_d2c_ack/{thing_name}/2.1/6'
        topics.dl = f'$aws/rules/msg_d2c_dl/{thing_name}/2.1/7'
        return topics
