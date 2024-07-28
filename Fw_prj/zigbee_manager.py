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
import RPi.GPIO as GPIO

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

def create_zigbee_network(serial_port, queue, queue_fb,queue_log,queue_sim):
    init_serial(serial_port)
    execute_command(f"/home/pi/Z3gateway_2 -p {serial_port} -b 115200", queue, queue_fb,queue_log,queue_sim)

def control_led(state):
    GPIO.output(config.LED_PIN, GPIO.LOW)
    if state == "ON":
        GPIO.output(config.LED_PIN, GPIO.HIGH)
        time.sleep(config.LED_ON_DURATION)
        GPIO.output(config.LED_PIN, GPIO.LOW)
    elif state == "BLINK":
        end_time = time.time() + config.LED_BLINK_DURATION  # Blink for 5 seconds
        while time.time() < end_time:
            GPIO.output(config.LED_PIN, GPIO.HIGH)
            time.sleep(0.2)
            GPIO.output(config.LED_PIN, GPIO.LOW)
            time.sleep(0.2)
        GPIO.output(config.LED_PIN, GPIO.HIGH)  # Keep LED on after blinking
        time.sleep(config.LED_ON_DURATION)  # Keep LED on for 250 seconds
        GPIO.output(config.LED_PIN, GPIO.LOW)  # Turn off LED after 250 seconds
    elif state == "OFF":
        GPIO.output(config.LED_PIN, GPIO.LOW) 
              
def action_network(child, action,queue_log):
    cmds = []
    if action == 1:
        cmds = config.OPEN_NETWORK
        queue_log.put(Log(
                "ffff",msg= config.OPEN_NETWORK_LOG
            ))        
        control_led("ON") 
    elif action == 2:
        cmds = config.RESET_NETWORK
        queue_log.put(Log(
                "ffff",msg= config.RESET_NETWORK_LOG
            ))
        control_led("BLINK") 
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

def execute_command(cmd, queue, queue_fb,queue_log,queue_sim):
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
                                process_data(child,device,queue_log,queue_sim) # generate log
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
            air = payload_int_list[3]
            fire = payload_int_list[4]    
            level = payload_int_list[5]         
            
            
            print(f"Node ID: {source_node_id}, Temperature: {temperature}, Humidity: {humidity}, Air: {air}, Fire: {fire}, Level: {level}")            
            
            write_to_file(log_file, f"Node ID: {source_node_id}, Temperature: {temperature}, Humidity: {humidity}, Air: {air}, Fire: {fire}, Level: {level}") 
            
            return Device(id= source_node_id,fire=fire, hum=humidity, name=source_node_id, air=air, temp=temperature, level=level)
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

def main(queue,queue_fb,queue_log,queue_sim):
    create_zigbee_network(config.SERIAL_PORT, queue, queue_fb,queue_log,queue_sim)
    serial_log, network_status = read_serial_data()
    print("Network Status:", network_status)
    execute_command(f"/home/pi/Z3gateway_2 -p {config.SERIAL_PORT} -b 115200", queue,queue_fb,queue_log,queue_sim)

