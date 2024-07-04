import threading
import sys
from queue import Queue
from button_reader import ButtonReader
import zigbee_manager
from firebase_service import FirebaseService

firebase = FirebaseService()

def button_listener(queue):
    button_reader = ButtonReader(5, queue)
    button_reader.start()
    button_reader.join()

def zigbee_network_manager(serial_port, queue):
    zigbee_manager.main(serial_port, queue)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the serial port")
        sys.exit(1)
    serial_port = sys.argv[1]
    
    # Initialize the system in Firebase
    firebase.initialize_system()
    
    # Create a queue to handle communication between threads
    queue = Queue()
    
    # Create and start the button listener thread
    button_thread = threading.Thread(target=button_listener, args=(queue,))
    button_thread.start()
    
    # Create and start the Zigbee network manager thread
    zigbee_thread = threading.Thread(target=zigbee_network_manager, args=(serial_port, queue))
    zigbee_thread.start()

    # Wait for both threads to complete
    button_thread.join()
    zigbee_thread.join()