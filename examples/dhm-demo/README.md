This Component example collects system information and relays it to /IOTCONNECT, including 
some of this info and similar:
* CPU model, architecture, OS details.
* CPU total, utilization, top CPU consuming process.
* RAM total, utilization, top RAM consuming process.
* Filesystem storage total and utilization.

The following C2D Commands can be sent from /IOTCONNECT:
- ```list-leds``` - Lists available LEDs on the system
- ```set-led <name> <[on|off>``` - Set specific leds to either ```on``` or ```off```

On most systems, the user under which the Component will be running will not be authorized to manipulate system LEDs.
Please set user permissions and/or UDEV rules accordingly. For example, assuming *ggcore* is the greengrass user,
add ```/etc/udev/rules.d/99-leds.rules``` so that a certain group, to which ggcore is ultimately added can write leds.

A quick "fix" could be to allow all users to modify LEDs:
```
echo 'ACTION=="add", SUBSYSTEM=="leds", MODE="0666"' | sudo tee /etc/udev/rules.d/99-leds.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger
```