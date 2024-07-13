import RPi.GPIO as GPIO
import time
import threading
from queue import Queue

class ButtonReader(threading.Thread):
    def __init__(self, pin, queue, debounce_delay=0.05):
        threading.Thread.__init__(self)
        self.pin = pin
        self.queue = queue
        self.debounce_delay = debounce_delay
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.pin, GPIO.IN)
        self.last_button_press_time = None
        self.last_button_state = GPIO.input(self.pin)
        self.last_debounce_time = time.time()
        GPIO.setwarnings(False)  # Disable GPIO warnings

    def update_button_state(self):
        """Check the button state and handle debouncing."""
        current_state = GPIO.input(self.pin) == 0
        if current_state != self.last_button_state:
            self.last_debounce_time = time.time()
        self.last_button_state = current_state

        if (time.time() - self.last_debounce_time) > self.debounce_delay:
            # Button state is stable after the debounce delay
            return current_state
        return None

    def check_button(self):
        """Process button press and categorize as short or long press."""
        stable_state = self.update_button_state()
        if stable_state is None:
            return 0

        if stable_state and self.last_button_press_time is None:
            self.last_button_press_time = time.time()

        if not stable_state and self.last_button_press_time is not None:
            press_duration = time.time() - self.last_button_press_time
            self.last_button_press_time = None
            if press_duration >= 3:
                return 2  # Long press
            else:
                return 1  # Short press

        return 0

    def run(self):
        try:
            while True:
                result = self.check_button()
                if result != 0:
                    self.queue.put(result)
                time.sleep(0.1)  # Short delay to reduce CPU usage
        except KeyboardInterrupt:
            print("Button reading terminated")
        finally:
            self.cleanup()

    def cleanup(self):
        """Clean up by resetting GPIO settings."""
        GPIO.cleanup()



def main():
    # Setup GPIO pin for the button
    BUTTON_PIN = 5  # Change this to your actual GPIO pin

    # Create a queue to communicate with the ButtonReader thread
    button_queue = Queue()

    # Create and start the ButtonReader thread
    button_reader = ButtonReader(BUTTON_PIN, button_queue)
    button_reader.start()

    print("Press the button to test...")

    try:
        while True:
            if not button_queue.empty():
                result = button_queue.get()
                if result == 1:
                    print("Short press detected")
                elif result == 2:
                    print("Long press detected")
            time.sleep(0.1)  # Short delay to reduce CPU usage
    except KeyboardInterrupt:
        print("Exiting program")
    finally:
        # Clean up GPIO settings
        button_reader.cleanup()
        GPIO.cleanup()

if __name__ == "__main__":
    main()