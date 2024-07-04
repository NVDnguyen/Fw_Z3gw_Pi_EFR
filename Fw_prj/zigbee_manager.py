import os
import sys
import re
import time
import serial
import config
import pexpect
from queue import Queue, Empty
from datetime import datetime
from device_obj import Device
from firebase_service import FirebaseService

# Global variables
log_file = "/home/pi/documents/Python/Fw_prj/Logs/log_data.txt" 
log_out = "/home/pi/documents/Python/Fw_prj/Logs/log_z3gw.txt"
last_written_content = None

firebase = FirebaseService()

def init_serial(port):
    global ser
    try:
        ser = serial.Serial(port, 115200)
    except Exception as e:
        print(f"Failed to initialize serial port {port}: {str(e)}")
        sys.exit(1)

def read_serial_data():
    try:
        data = ser.read(1024)
        if data:
            return data.decode('utf-8'), "Active"
    except serial.SerialException as e:
        print(f"Error reading from serial port: {str(e)}")
        return "", "Error"
    return "", "No Data"

def create_zigbee_network(serial_port, queue):
    init_serial(serial_port)
    execute_command(f"/home/pi/Z3gateway_2 -p {serial_port} -b 115200", queue)
      
def action_network(child, action):
    cmds = []
    if action == 1:
        cmds = config.OPEN_NETWORK
    elif action == 2:
        cmds = config.RESET_NETWORK
    else:
        print(f"Unknown action: {action}")
        return
    
    for cmd in cmds:
        print(f"Executing custom command: {cmd}")
        child.sendline(cmd)
        
def start_network(child):
    cmds = [
        "plugin network-creator start 1",
        "plugin network-creator-security open-network"
    ]
    for cmd in cmds:
        print(f"Executing custom command: {cmd}")
        child.sendline(cmd)

def execute_command(cmd, queue) -> str:
    try:
        print(f"Executing command: {cmd}")
        child = pexpect.spawn(cmd, encoding='utf-8')

        log_output = []
        while True:
            # Check size of file 
            check_and_delete_old_logs(log_file, config.MAX_LOG_SIZE_BYTES)
            # Check for button events
            try:
                state_button = queue.get_nowait()
                action_network(child,state_button)
            except Empty:
                pass  # No button event, continue
            except Exception as e:
                print(f"Error processing button event: {str(e)}")
                
            # Process Z3gateway
            index = child.expect([pexpect.TIMEOUT, pexpect.EOF, '\r\n'], timeout=0.1)
            if index == 0:  # Timeout
                continue
            elif index == 1:  # EOF
                break
            elif index == 2:  # Newline received
                output = child.before.strip()
                if output:
                    #print(output)
                    log_output.append(output)

                    if output.startswith('T'):
                        dv = extract_payload(output)
                        # Upload to Firebase
                        if dv:
                            firebase.upload_to_firebase(dv)
                        # Proccess data

                    write_to_file(log_out, output)

        return '\n'.join(log_output).strip()

    except Exception as err:
        print(f"Execute command error: {str(err)}")
        return str(err)

def extract_payload(output):
    payload_pattern = r'payload\[(.*?)\]'
    match_payload = re.search(payload_pattern, output)
    if match_payload:
        payload_hex = match_payload.group(1)
        payload_int_list = [int(x, 16) for x in payload_hex.split()]
        if len(payload_int_list) >= 7:  
            source_high_byte = payload_int_list[0]
            source_low_byte = payload_int_list[1]
            source_node_id = (source_high_byte << 8) + source_low_byte
            temperature = payload_int_list[2]
            humidity = payload_int_list[3]
            smoke = payload_int_list[4]
            fire = payload_int_list[5]
            
            print(f"Node ID: {source_node_id}, Temperature: {temperature}, Humidity: {humidity}, Smoke: {smoke}, Fire: {fire}")  
            write_to_file(log_file, f"Node ID: {source_node_id}, Temperature: {temperature}, Humidity: {humidity}, Smoke: {smoke}, Fire: {fire}") 
            
            return Device(fire=fire, hum=humidity, name=source_node_id, smoke=smoke, temp=temperature)
    return None


def write_to_file(file_name, content):
    global last_written_content
    try:
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(file_name, 'a') as f:
            f.write(f"{current_time} - {content}\n")
        last_written_content = content
    except Exception as e:
        print(f"Write file {file_name} error: {str(e)}")

def check_and_delete_old_logs(file_name, max_size_bytes):
    try:
        if os.path.getsize(file_name) > max_size_bytes:
            with open(file_name, 'r') as f:
                lines = f.readlines()
            with open(file_name, 'w') as f:
                f.writelines(lines[-100:])  # Keep the latest 100 records
            #print(f"Deleted old log records, keeping the latest 100 records.")
    except Exception as e:
        print(f"Error checking and deleting old logs: {str(e)}")

def main(serial_port, queue):
    create_zigbee_network(serial_port, queue)
    serial_log, network_status = read_serial_data()
    print("Network Status:", network_status)
    execute_command(f"/home/pi/Z3gateway_2 -p {serial_port} -b 115200", queue)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the serial port")
        sys.exit(1)
    serial_port = sys.argv[1]
    queue = Queue()
    main(serial_port, queue)
