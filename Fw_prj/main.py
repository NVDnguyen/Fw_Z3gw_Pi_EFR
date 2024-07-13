import threading
import sys
import time
from queue import Queue
from button_reader import ButtonReader
import zigbee_manager
from firebase_service import upload_to_firebase ,initialize_system, up_log,get_phone_numbers
from sim_com import init_sim

def button_listener(queue):
    button_reader = ButtonReader(5, queue)
    button_reader.start()
    button_reader.join()

def zigbee_network_manager(queue, queue_fb,queue_log):
    try:
        zigbee_manager.main(queue, queue_fb,queue_log)
    except Exception as e:
        print(f"Zigbee Network Manager Error: {str(e)}")

def firebase_up_data(queue_fb,queue_log):
    list = get_phone_numbers()
    print(list)
    while True:
        try:
            if not queue_fb.empty():
                device = queue_fb.get()
                upload_to_firebase(device) 
            if not queue_log.empty():
                log = queue_log.get()
                up_log(log) 
            time.sleep(1)
        except Exception as e:
            print(f"Firebase Upload Data Error: {str(e)}")

if __name__ == "__main__":
   
    initialize_system()
    init_sim()
    
    queue = Queue()
    queue_fb = Queue()
    queue_log = Queue()
    
    button_thread = threading.Thread(target=button_listener, args=(queue,))
    zigbee_thread = threading.Thread(target=zigbee_network_manager, args=(queue, queue_fb,queue_log))
    firebase_thread = threading.Thread(target=firebase_up_data, args=(queue_fb,queue_log))

    button_thread.start()
    zigbee_thread.start()
    firebase_thread.start()

    button_thread.join()
    zigbee_thread.join()
    firebase_thread.join()
