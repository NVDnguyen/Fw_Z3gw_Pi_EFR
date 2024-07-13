import os
import sys
import re
import time
import serial # type: ignore
import config
import pexpect # type: ignore
from queue import Queue, Empty
from datetime import datetime
from obj import Device
from obj import Log
from data_analyst import process_data
# Global variables
log_file = "/home/pi/documents/Python/Fw_prj/Logs/log_data.txt" 
log_out = "/home/pi/documents/Python/Fw_prj/Logs/log_z3gw.txt"
last_written_content = None

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

def create_zigbee_network(serial_port, queue, queue_fb,queue_log):
    init_serial(serial_port)
    execute_command(f"/home/pi/Z3gateway_2 -p {serial_port} -b 115200", queue, queue_fb,queue_log)
      
def action_network(child, action,queue_log):
    cmds = []
    if action == 1:
        cmds = config.OPEN_NETWORK
        queue_log.put(Log(
                "1",msg= config.OPEN_NETWORK_LOG
            )) 
    elif action == 2:
        cmds = config.RESET_NETWORK
        queue_log.put(Log(
                "1",msg= config.RESET_NETWORK_LOG
            )) 
    elif action == 3:
        cmds = config.SEND_NODE_ACTION
    else:
        print(f"Unknown action: {action}")
        return
    
    for cmd in cmds:
        print(f"Executing custom command: {cmd}")
        child.sendline(cmd)
        
def start_network(child):
    cmds = config.START_NETWORK
    for cmd in cmds:
        print(f"Executing custom command: {cmd}")
        child.sendline(cmd)

def execute_command(cmd, queue, queue_fb,queue_log):
    try:
        print(f"Executing command: {cmd}")
        child = pexpect.spawn(cmd, encoding='utf-8')
        time.sleep(1)
        start_network(child)
        while True: 
            # Check size of file 
            check_and_delete_old_logs(log_file, config.MAX_LOG_SIZE_BYTES)

            # Check for button events
            try:
                state_button = queue.get_nowait()
                action_network(child, state_button,queue_log)
            except Empty:
                pass  # No button event, continue
            except Exception as e:
                print(f"Error processing button event: {str(e)}")

            # Process Z3gateway output
            index = child.expect([pexpect.TIMEOUT, pexpect.EOF, '\r\n'], timeout=0.1)
            if index == 0:  # Timeout, continue looping
                continue
            elif index == 1:  # EOF, break out of the loop
                break
            elif index == 2:  # Newline received, process the output
                output = child.before.strip()
                if output:
                    write_to_file(log_out,output)

                    if output.startswith('T'):
                        device = extract_payload(output)
                        if device:
                            queue_fb.put(device) # data share firebase
                            try:
                                process_data(child,device,queue_log) # generate log
                            except Exception  as e:
                                print(f"Error process data: {str(e)}")
                                                     

        return '\n'.strip()
    except Exception as err:
        print(f"Execute command error: {str(err)}")
        queue_log.put(Log(
                "1",msg= config.ERROR_EXE_LOG
            )) 
        return str(err)


def extract_payload(output):
    payload_pattern = r'payload\[(.*?)\]'
    match_payload = re.search(payload_pattern, output)
    if match_payload:
        payload_hex = match_payload.group(1)
        payload_int_list = [int(x, 16) for x in payload_hex.split()]
        if len(payload_int_list) >= 5:  
            source_node_id = payload_int_list[0]
            temperature = payload_int_list[1]
            humidity = payload_int_list[2]
            ch4 = payload_int_list[3]
            co = payload_int_list[4]             
            fire = payload_int_list[5]
            
            print(f"Node ID: {source_node_id}, Temperature: {temperature}, Humidity: {humidity}, CH4: {ch4}, CO:{co} Fire: {fire}")            
            
            write_to_file(log_file, f"Node ID: {source_node_id}, Temperature: {temperature}, Humidity: {humidity}, CH4: {ch4}, CO:{co} Fire: {fire}") 
            
            return Device(id= source_node_id,fire=fire, hum=humidity, name=source_node_id, ch4=ch4,co=co, temp=temperature)
    return None

                  
        
            
    

def write_to_file(file_name, content):
    global last_written_content
    try:
        current_time = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
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

def main(queue,queue_fb,queue_log):
    create_zigbee_network(config.SERIAL_PORT, queue, queue_fb,queue_log)
    serial_log, network_status = read_serial_data()
    print("Network Status:", network_status)
    execute_command(f"/home/pi/Z3gateway_2 -p {config.SERIAL_PORT} -b 115200", queue,queue_fb,queue_log)

