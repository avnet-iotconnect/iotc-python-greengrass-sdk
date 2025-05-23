import os
import sys
import time
from dataclasses import asdict

from avnet.iotconnect.sdk.sdklib.error import ClientError
from avnet.iotconnect.sdk.sdklib.mqtt import C2dOta, C2dAck

from avnet.iotconnect.sdk.greengrass import Client, C2dCommand, Callbacks

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import systemdata
import systemleds


def on_command(msg: C2dCommand):
    print("Received command", msg.command_name, msg.command_args, msg.ack_id)
    if msg.command_name == "list-leds":
        leds = systemleds.list_leds()
        if len(leds) == 0:
            c.send_command_ack(msg, C2dAck.CMD_SUCCESS_WITH_ACK, "No System Leds")
        else:
            c.send_command_ack(msg, C2dAck.CMD_SUCCESS_WITH_ACK, ", ".join(leds))
    elif msg.command_name == "set-led":
        if len(msg.command_args) in (1, 2):
            name = None
            state_str = msg.command_args[0]
            if len(msg.command_args) == 2:
                name = msg.command_args[1]
            state = False
            if "1" == state_str or "true" == state_str.lower() or "on" == state_str.lower():
                state = True
            status, message = systemleds.set_system_led(state, name)
            if status:
                # message will contain the name of the LED that was set
                message = f"LED {message} set successfully"
                # otherwise message will be error
            c.send_command_ack(msg, C2dAck.CMD_SUCCESS_WITH_ACK if status else C2dAck.CMD_FAILED, message)
            print(message)
        else:
            c.send_command_ack(msg, C2dAck.CMD_FAILED, "Expected 1 or 2 arguments")
            print("Expected 1 or 2 command arguments, but got", len(msg.command_args))
    else:
        print("Command %s not implemented!" % msg.command_name)
        # You can send a failure ack for unrecognised commands, but other components may be servicing those commands,
        # so we should not do this for Greengrass unless we know that we will be the only /IOTCONNECT component running
        #
        # if msg.ack_id is not None: # it could be a command without "Acknowledgement Required" flag in the device template
        #    c.send_command_ack(msg, C2dAck.CMD_FAILED, "Not Implemented")


def send_telemetry():
    # Send simple data using a basic dictionary
    c.send_telemetry(asdict(systemdata.collect_data()))


try:
    c = Client(
        callbacks=Callbacks(
            command_cb=on_command
        )
    )
    while True:
        send_telemetry()
        time.sleep(30)

except ClientError as dce:
    print(dce)
    sys.exit(1)
