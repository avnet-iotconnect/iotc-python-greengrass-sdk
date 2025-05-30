This example is an example Component implementation that can:
* Attempts to open /dev/ttyACM0 by default.
* Can open a different serial port per command from /IOTCONNECT ```serial-open <port> [baudrate]``` where *port* 
is a system port to open with optional baudrate (default 115200)
* Can send a command sent from /IOTCONNECT ```serial-send [command to send]``` appending a newline (\\n) to the command.
Invoking this command with no arguments will send just the newline.
* Any data received on the port will be sent as **serial_data** telemetry value.
