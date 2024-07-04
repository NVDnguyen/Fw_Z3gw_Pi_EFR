import serial
import time

class SIMModule:
    def __init__(self, port, baud_rate=115200):
        self.port = port
        self.baud_rate = baud_rate
        self.serial = serial.Serial(port, baud_rate, timeout=1)
        self.initialize_sim()

    def initialize_sim(self):
        print("Initializing SIM module...")
        if self.send_at_command("AT"):
            print("SIM module is ready.")
        else:
            print("Failed to initialize SIM module.")

    def send_at_command(self, command, timeout=3):
        self.serial.write((command + "\r\n").encode())
        start_time = time.time()
        while True:
            if time.time() - start_time > timeout:
                return False
            if self.serial.in_waiting:
                response = self.serial.read_all().decode().strip()
                print(response)
                return True

    def send_sms(self, number, message):
        print("Sending SMS...")
        self.send_at_command("AT+CMGF=1")  # Set to text mode
        time.sleep(1)
        self.send_at_command(f'AT+CMGS="{number}"')
        time.sleep(1)
        self.serial.write((message + "\x1A").encode())  # CTRL+Z to send
        time.sleep(1)
        print("SMS sent to", number)

    def make_call(self, number):
        print("Making a call...")
        self.send_at_command(f"ATD{number};")
        print("Dialing", number)

    def demo(self):
        # Example usage
        if self.send_at_command("AT+CPIN?"):
            self.send_at_command("AT+CSQ")
            self.send_sms("0387015635", "Hello, this is a test message.")
            self.make_call("0387015635")

# Example usage
sim_module = SIMModule("/dev/ttyUSB0")  # Change the port as needed
sim_module.demo()
