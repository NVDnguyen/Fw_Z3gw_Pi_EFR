import json
import os
from queue import Queue, Empty
from datetime import datetime
from obj import Device
from obj import Log
import config
from sim_com import check_sim,init_sim,make_call,send_sms
from firebase_service import get_phone_numbers
from led_RGB import blue_light, green_light, red_light, turn_off

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
    # elif action == 3:
    #     cmds = config.SEND_NODE_ACTION
    else:
        print(f"Unknown action: {action}")
        return
    
    for cmd in cmds:
        print(f"Executing custom command: {action} -> {cmd}")
        child.sendline(cmd)
   


# Assume prev_risk_levels is a dictionary storing previous risk levels of devices
prev_risk_levels = {}

def process_data(child, device, queue_log, queue_sim):
    if isinstance(device, Device):
        risk_level = int(device.level)
        
        # turn on led
        if risk_level == 3:
            red_light()
        elif risk_level == 2:
            blue_light()
        elif risk_level == 1:
            green_light()
        else :
            turn_off()
        
        
        # Check and store the previous risk level, assume 0 if there is no previous value
        prev_risk_level = prev_risk_levels.get(device.id, 0)
        
        # Update the new risk level into the dictionary
        prev_risk_levels[device.id] = risk_level
        
        # Check if the risk level has changed from the previous level
        if risk_level != prev_risk_level:
            if risk_level == 3:
                queue_log.put(Log(device.id, msg=config.RISK3_LOG))
                #queue_sim.put(3)
                #action_with_Sim(3)
                
                
            elif risk_level == 2:
                queue_log.put(Log(device.id, msg=config.RISK2_LOG))
                # queue_sim.put(2)
                #action_with_Sim(2)
                
            elif risk_level == 1:
                queue_log.put(Log(device.id, msg=config.RISK1_LOG))
                # queue_sim.put(1)
                #action_with_Sim(1)


            
def action_with_Sim(action):
    try:
        listPhone = get_phone_numbers_from_file()
        if listPhone:
            # Ensure phone numbers start with '0'
            listPhone = ['0' + str(phone) if not str(phone).startswith('0') else str(phone) for phone in listPhone]


            # Initialize SIM if not already done
            if not check_sim():
                init_sim()

            if action == 3:
                # Call and send SMS to all phone numbers
                for phone in listPhone:
                    if make_call(phone):
                        print("CALL finish")
                        break
            elif action == 2:
                print("Send SMS")
            elif action == 1:
                # Only send SMS to all phone numbers
                for phone in listPhone:
                    send_sms(phone, config.ALERT_MESSAGE)
            else:
                print("Unknown action.")
        else:
            print("The list of phone numbers is None.")
    except Exception as e:
        print(f"Error in action_with_Sim: {e}")
    

def get_phone_numbers_from_file():
    try:
        with open(config.PHONES_FILE, 'r') as file:
            phone_numbers = json.load(file)
        return phone_numbers
    except Exception as e:
        print(f"Error reading phone numbers from file: {e}")
        return []    
        
    
