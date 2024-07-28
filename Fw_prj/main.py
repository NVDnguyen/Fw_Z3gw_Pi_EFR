import threading
import sys
import time
from queue import Queue
from button_reader import ButtonReader
from data_analyst import action_with_Sim
import zigbee_manager
from firebase_service import upload_to_firebase ,initialize_system, up_log,get_phone_numbers,save_phone_numbers_to_file
from sim_com import init_sim
import config
import RPi.GPIO as GPIO
from led_RGB import setup_pins

GPIO.setmode(GPIO.BCM)
GPIO.setup(config.LED_PIN, GPIO.OUT)

def button_listener(queue):
    button_reader = ButtonReader(5, queue)
    button_reader.start()
    button_reader.join()

def zigbee_network_manager(queue, queue_fb,queue_log,queue_sim):
    try:
        zigbee_manager.main(queue, queue_fb,queue_log,queue_sim)
    except Exception as e:
        print(f"Zigbee Network Manager Error: {str(e)}")

def firebase_up_data(queue_fb,queue_log):
    list = get_phone_numbers()    
    save_phone_numbers_to_file(list, config.PHONES_FILE)
    while True:
        try:
            if not queue_fb.empty():
                device = queue_fb.get()
                upload_to_firebase(device) 
            if not queue_log.empty():
                log = queue_log.get()
                up_log(log) 
            # time.sleep(1)
        except Exception as e:
            print(f"Firebase Upload Data Error: {str(e)}")
def action_sim(queue_sim):
    while True:
        try:
            if not queue_sim.empty():
                action = queue_sim.get()
                action_with_Sim(action)

        except Exception as e:
            print(f"sim thread {str(e)}")
if __name__ == "__main__":
   
    initialize_system()
    init_sim()
    setup_pins()
    
    queue = Queue()
    queue_fb = Queue()
    queue_log = Queue()
    queue_sim = Queue()
    
    button_thread = threading.Thread(target=button_listener, args=(queue,))
    zigbee_thread = threading.Thread(target=zigbee_network_manager, args=(queue, queue_fb,queue_log,queue_sim))
    firebase_thread = threading.Thread(target=firebase_up_data, args=(queue_fb,queue_log))
    #sim_thread = threading.Thread(target= action_sim,args=(queue_sim,))

    button_thread.start()
    zigbee_thread.start()
    firebase_thread.start()
    #sim_thread.start()

    button_thread.join()
    zigbee_thread.join()
    firebase_thread.join()
    #sim_thread.join()
    
    GPIO.cleanup()
