from queue import Queue, Empty
from datetime import datetime
from obj import Device
from obj import Log
import config
from sim_com import check_sim,init_sim,make_call,send_sms
from firebase_service import get_phone_numbers


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
   


def process_data(child,device,queue_log):
    if isinstance(device, Device):
        risk_level = int(device.fire)
        if risk_level == 3 :
            # send msg to all note to turn on Alarm
            #action_network(child,3,queue_log)         
            queue_log.put(Log(
                device.id,msg= config.RISK3_LOG
            ))
            action_with_Sim(3)
            
        elif risk_level ==2 :
            queue_log.put(Log(
                device.id,msg= config.RISK2_LOG
            ))    
            action_with_Sim(2)
        elif risk_level == 1:
            queue_log.put(Log(
                device.id,msg= config.RISK1_LOG
            ))  
            action_with_Sim(1)
            
def action_with_Sim(action):
    
    try :
        listPhone = get_phone_numbers()
        if listPhone is not None:
        # Ensure phone numbers start with '0'
            listPhone = ['0' + phone if not phone.startswith('0') else phone for phone in listPhone]

        # Initialize SIM if not already done
        if not check_sim():
            init_sim()

        if action == 3:
            # Call and send SMS to all phone numbers
            for phone in listPhone:
                make_call(phone)
                #send_sms(phone, config.ALERT_MESSAGE)
        elif action ==2:
            print("Send SMS")
        elif action == 1:
            # Only send SMS to all phone numbers
            for phone in listPhone:
                send_sms(phone, config.ALERT_MESSAGE)
        else:
            print("The list of phone numbers is None.")
    except Exception  as e:
        print("Déo gọi được :"+e)
    
    
        
    
