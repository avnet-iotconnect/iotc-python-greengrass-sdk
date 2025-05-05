import random
import random
import sys
import time
from dataclasses import dataclass, asdict

from avnet.iotconnect.sdk.sdklib.error import ClientError
from avnet.iotconnect.sdk.sdklib.mqtt import C2dOta, C2dAck

from avnet.iotconnect.sdk.greengrass import Client, C2dCommand, TelemetryRecord, Callbacks
from avnet.iotconnect.sdk.greengrass import __version__ as SDK_VERSION


@dataclass
class ExampleAccelerometerData:
    x: float
    y: float
    z: float


@dataclass
class ExampleSensorData:
    temperature: float
    humidity: float
    accel: ExampleAccelerometerData


def send_telemetry():
    # Send simple data using a basic dictionary
    c.send_telemetry({
        'sdk_version': SDK_VERSION,
        'random': random.randint(0, 100),
        'accel': {
            'x': 33.44,
            'y': 55.6,
            'z': 0.5
        },
        'lat_long': [34, -43.22233]
    })

    # ...or send structured data. Make sure your object has the @dataclass decorator
    data = ExampleSensorData(
        humidity=30.43,
        temperature=22.8,
        accel=ExampleAccelerometerData(
            x=0.565,
            y=0.334,
            z=0,
        )
    )
    c.send_telemetry(asdict(data))

    # We can update the data by assigning new values to the object before sending it again
    data.temperature = 23.1
    data.accel.x = 0.573
    data.accel.z = 0.002
    c.send_telemetry(asdict(data))

    # Example of sending multiple telemetry records by accumulating data.
    # A use case could be one where we save device power by staying disconnected but periodically waking up to record data,
    # and then we send accumulated data at once (note that there is a limit to maximum IoTConnect packet size)
    records: list[TelemetryRecord] = []

    data.temperature = 34.4
    records.append(TelemetryRecord(asdict(data), timestamp=Client.timestamp_now()))

    time.sleep(2)  # wait some time and the update the record with new sensor readings
    data.temperature = 34.6
    records.append(TelemetryRecord(asdict(data), timestamp=Client.timestamp_now()))

    # multiple records will be sent with different timestamps
    c.send_telemetry_records(records)


def on_command(msg: C2dCommand):
    print("Received command", msg.command_name, msg.command_args, msg.ack_id)
    if msg.command_name == "set-user-led":
        if len(msg.command_args) == 3:
            # pretend that we actually RGB values
            status_message = "Setting User LED to R:%d G:%d B:%d" % (int(msg.command_args[0]), int(msg.command_args[1]), int(msg.command_args[2]))
            c.send_command_ack(msg, C2dAck.CMD_SUCCESS_WITH_ACK, status_message)
            print(status_message)
        else:
            c.send_command_ack(msg, C2dAck.CMD_FAILED, "Expected 3 arguments")
            print("Expected three command arguments, but got", len(msg.command_args))
    else:
        print("Command %s not implemented!" % msg.command_name)
        # You can send a failure ack for unrecognised commands, but other components may be servicing those commands,
        # so we should not do this for Greengrass
        #
        # if msg.ack_id is not None:  # it could be a command without "Acknowledgement Required" flag in the device template
        #    c.send_command_ack(msg, C2dAck.CMD_FAILED, "Not Implemented")


def on_ota(msg: C2dOta):
    # IMPORTANT: When implementing a failure ack, ensure that we are
    # THE ONLY /IOTCONNECT component that may be handling OTA

    # We just print the URL. The actual handling of the OTA request would be project specific.
    # See the ota-handling.py for more details.
    print("Received OTA request. File: %s Version: %s URL: %s" % (msg.urls[0].file_name, msg.version, msg.urls[0].url))
    # OTA messages always have ack_id, so it is safe to not check for it before sending the ack
    c.send_ota_ack(msg, C2dAck.OTA_DOWNLOAD_FAILED, "Not implemented")


try:
    c = Client(
        callbacks=Callbacks(
            command_cb=on_command,
            ota_cb=on_ota
        )
    )
    while True:
        send_telemetry()
        time.sleep(30)

except ClientError as ce:
    print(ce)
    sys.exit(1)
