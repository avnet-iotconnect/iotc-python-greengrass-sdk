import os
import time
from typing import List, Optional, Tuple


def list_leds() -> List[str]:
    """Returns a list of available LED names, or empty list if none found or any error is encountered."""
    leds_path = "/sys/class/leds"
    try:
        if os.path.exists(leds_path):
            return sorted([led for led in os.listdir(leds_path)
                           if not led.startswith('.') and
                           os.path.isdir(os.path.join(leds_path, led))])
    except OSError:
        pass
    return []


def set_system_led(state: bool, name: Optional[str] = None) -> Tuple[bool, str]:
    """
    Sets the brightness of a specific system LED (partial names allowed)
    or a first available led in alphabetical order led from all available

    :param state: True to turn on, False to turn off
    :param name: Optional substring to match in LED name. If None, uses first available LED.

    :return: Tuple of (success: bool, message: str) where str is the name of the led or error message if success if false
    """
    leds = list_leds()
    if not leds:
        return False, "No LEDs found"

    # Find matching LED
    target_led = None
    if name:
        matching_leds = [led for led in leds if name.lower() in led.lower()]
        if not matching_leds:
            return False, f"No LED found containing '{name}'"
        target_led = matching_leds[0]
    else:
        target_led = leds[0]

    # Verify control files
    brightness_path = f"/sys/class/leds/{target_led}/brightness"
    max_path = f"/sys/class/leds/{target_led}/max_brightness"

    if not all(os.path.exists(p) for p in [brightness_path, max_path]):
        return False, f"LED control files missing for {target_led}"

    # Set brightness
    try:
        with open(max_path) as f:
            max_brightness = int(f.read().strip())

        with open(brightness_path, 'w') as f:
            f.write(str(max_brightness if state else 0))
        return True, target_led

    except PermissionError:
        error_msg = f"Permission denied for LED {target_led}"
        return False, error_msg
    except RuntimeError as e:
        return False, f"Failed to control LED: {str(e)}"

if __name__ == "__main__":
    print(", ".join(list_leds()))
    print(set_system_led(True))
    time.sleep(1)
    print(set_system_led(False))
    time.sleep(1)
    print(set_system_led(False, "numlock"))
    time.sleep(1)
    print(set_system_led(True, "numlock"))
