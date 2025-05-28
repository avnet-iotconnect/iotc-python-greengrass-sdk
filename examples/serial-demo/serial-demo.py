import sys
import time
from typing import Optional

import serial
from avnet.iotconnect.sdk.sdklib.error import ClientError
from avnet.iotconnect.sdk.sdklib.mqtt import C2dAck

from avnet.iotconnect.sdk.greengrass import Client, C2dCommand, Callbacks
from avnet.iotconnect.sdk.greengrass import __version__ as SDK_VERSION


class SerialPort:
    def __init__(
            self,
            port: str = 'dev/ttyACM0',
            baudrate: int = 115200,
            parity: str = serial.PARITY_NONE,
            stopbits: float = serial.STOPBITS_ONE,
            bytesize: int = serial.EIGHTBITS,
    ):
        self.port: str = port
        self.baudrate: int = baudrate
        self.parity: str = parity
        self.stopbits: float = stopbits
        self.bytesize: int = bytesize

    def open(self, quiet=False) -> Optional[serial.Serial]:
        try:
            ser = serial.Serial(
                port=self.port,  # Replace with your serial port
                baudrate=self.baudrate,
                parity=self.parity,
                stopbits=self.stopbits,
                bytesize=self.bytesize,
                timeout=2
            )
            ser.open()
            return ser
        except serial.SerialException as e:
            if not quiet:
                print(f"Serial Error while opening port {self.port}: {e}")
            return None


s: Optional[serial.Serial] = SerialPort().open(quiet=False) # (loud for now) with default args like dev/ttyACM0 at 115200 baudrate

def send_port_data():
    global s
    try:
        if s is not None and s.is_open:
            while s.in_waiting > 0:
                line = s.readline().decode('utf-8').rstrip()
                if line is not None and len(line) > 0:
                    c.send_telemetry({
                        'serial_data': line
                    })
    except serial.SerialException as e:
        print(f"Serial Error: {e}")


def on_command(msg: C2dCommand):
    global s
    print("Received command", msg.command_name, msg.command_args, msg.ack_id)
    if msg.command_name == "serial-open":
        # for now, we support only port name and baudrate
        if len(msg.command_args) == 2 or len(msg.command_args) == 1:
            # pretend that we actually RGB values
            port = msg.command_args[0]
            baudrate = 115200
            if len(msg.command_args) == 2:
                baudrate = int(msg.command_args[1])
                if baudrate <= 0:
                    print(f"Error parsing argument {msg.command_args[1]}")
                    c.send_command_ack(msg, C2dAck.CMD_FAILED, "Second argument must be baudrate")
                    return
            if s is not None:
                try:
                    s.close()
                except RuntimeError:
                    pass
                s = None
            s = SerialPort(port, baudrate).open()
        else:
            c.send_command_ack(msg, C2dAck.CMD_FAILED, "Expected 2 arguments")
            print("Expected two command arguments, but got", len(msg.command_args))
    elif msg.command_name == "serial-send":
        # for now, we support only port name and baudrate
        command_str = ""
        if len(msg.command_args) > 0:
            command_str = " ".join(msg.command_args)

        try:
            if s is not None and s.is_open:
                s.write(command_str.encode('utf-8'))
                s.write('\n'.encode('utf-8'))
            else:
                c.send_command_ack(msg, C2dAck.CMD_FAILED, "Port is not open")
                print(f"Error: Port is not open!")

        except serial.SerialException as e:
            print(f"Serial Error: {e}")


try:
    c = Client(
        callbacks=Callbacks(
            command_cb=on_command
        )
    )
    c.send_telemetry({
        'sdk_version': SDK_VERSION
    })

    while True:
        send_port_data()
        time.sleep(1)

except ClientError as ce:
    print(ce)
    sys.exit(1)
