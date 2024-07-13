import serial
import time

port = "/dev/ttyUSB0"  # Specify your port here
serial_conn = None  # Initialize serial_conn as None

def init_sim():
    global serial_conn
    try:
        serial_conn = serial.Serial(port, 115200, timeout=1)
    except serial.SerialException as e:
        print(f"Error initializing serial port: {e}")
        serial_conn = None

def send_at_command(command, timeout=3):
    global serial_conn
    if not serial_conn:
        print("Serial connection not initialized")
        return False
    try:
        serial_conn.write((command + "\r\n").encode())
        start_time = time.time()
        while True:
            if time.time() - start_time > timeout:
                print("Timeout waiting for response")
                return False
            if serial_conn.in_waiting:
                response = serial_conn.read_all().decode('utf-8').strip()
                print(response)
                return "OK" in response or "ERROR" not in response
    except serial.SerialException as e:
        print(f"Error sending AT command: {e}")
        return False

def check_sim():
    print("Checking SIM module...")
    return send_at_command("AT")

def send_sms(number, message):
    print("Sending SMS...")
    if send_at_command("AT+CMGF=1"):  # Set to text mode
        time.sleep(1)
        if send_at_command(f'AT+CMGS="{number}"'):
            time.sleep(1)
            serial_conn.write((message + "\x1A").encode())  # CTRL+Z to send
            time.sleep(3)
            print("SMS sent to", number)
        else:
            print("Failed to send SMS")
    else:
        print("Failed to set SMS text mode")

def make_call(number):
    print("Making a call...")
    if send_at_command(f"ATD{number};"):
        print(f"Calling {number}...")
    else:
        print("Failed to make call")

if __name__ == "__main__":
    init_sim()
    if serial_conn:
        if check_sim():
            print("SIM module is ready.")
        else:
            print("Failed to initialize SIM module.")
        
        #send_sms("0363802865", "He thong canh bao")
        make_call("0363802865")

        serial_conn.close()
    else:
        print("Failed to initialize serial connection")
