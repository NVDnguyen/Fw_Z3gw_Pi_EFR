import hashlib
import time
import random

def generate_unique_key():
    serial_number = get_raspberry_pi_serial_number()
    if serial_number is None:
        serial_number = 'UNKNOWN_SERIAL_NUMBER'
    
    # Combine the serial number with the current time and a random number
    unique_string = f"{serial_number}_{int(time.time())}_{random.randint(0, 1000000)}"
    
    # Use hashlib to create a unique hash
    hash_object = hashlib.sha256(unique_string.encode())
    unique_key = hash_object.hexdigest()[:10] 
    
    return unique_key


def get_raspberry_pi_serial_number():
    try:
        with open('/proc/cpuinfo', 'r') as file:
            for line in file:
                if line.startswith('Serial'):
                    serial = line.split(':')[1].strip()
                    return serial
    except Exception as e:
        print(f"An error occurred while reading CPU info: {e}")
        return None
    
system_id = get_raspberry_pi_serial_number()
print(f"Raspberry Pi system id: {system_id}")