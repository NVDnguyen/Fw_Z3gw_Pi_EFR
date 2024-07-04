import pyrebase
from datetime import datetime
from Utility.gen_system import get_raspberry_pi_serial_number
from Utility.gen_system import generate_unique_key

import config

class FirebaseService:
    def __init__(self):
        self.firebase = pyrebase.initialize_app(config.FIREBASE_CONFIG)
        self.db = self.firebase.database()
        self.system_id = get_raspberry_pi_serial_number()

    def initialize_system(self):
        # Check if system_id already exists in Firebase
        existing_system = self.db.child("Systems").child(self.system_id).get().val()
        if existing_system is not None:
            print(f"System {self.system_id} already exists in Firebase.")
            return

        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.key = generate_unique_key()
        data = {
            'Key': self.key,
            'admin': '',
            'devices': {},
            'name': self.system_id
        }
        self.db.child("Systems").child(self.system_id).set(data)
        msg = f"System {self.system_id} initialized successfully"
        device_id = "1"
        self.up_log(device_id, msg)

    def up_device(self, device_id, device_dict):
        existing_device = self.db.child("Systems").child(self.system_id).child("devices").child(device_id).get().val()
        if existing_device is None:
            self.db.child("Systems").child(self.system_id).child("devices").child(device_id).set(device_dict)
            msg = f"Device {device_id} added to system {self.system_id} successfully"
            print(msg)
            self.up_log(device_id, msg)
        else:
            device_dict_without_name = {k: v for k, v in device_dict.items() if k != 'name'}
            self.db.child("Systems").child(self.system_id).child("devices").child(device_id).update(device_dict_without_name)
            print(f"Device {device_id} updated in system {self.system_id} successfully")
    
    def upload_to_firebase(self, device):
        device_id = str(device.name)
        device_data = {
            'name': "id" + str(device.name),
            'temp': device.temp,
            'hum': device.hum,
            'smoke': device.smoke,
            'fire': device.fire,
        }
        self.up_device(device_id, device_data)
        
    def up_log(self, device_id, msg):
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = {f"{device_id}": msg} 
        self.db.child("Systems").child(self.system_id).child("log").child(current_time).update(log_entry)

    def get_device_name(self, device_id):
        return self.db.child("Systems").child(self.system_id).child("devices").child(device_id).child("name").get().val()

    def get_system_name(self):
        return self.db.child("Systems").child(self.system_id).child("name").get().val()

if __name__ == "__main__":
    service = FirebaseService()
    service.initialize_system()
