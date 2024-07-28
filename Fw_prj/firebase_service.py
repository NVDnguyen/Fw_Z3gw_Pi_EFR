import json
import os
import shutil
from datetime import datetime, timedelta
from firebase_admin import credentials, db, initialize_app
from obj import Log
from Utility.gen_system import get_raspberry_pi_serial_number, generate_unique_key
import config

# Initialize Firebase Admin
cred = credentials.Certificate('/home/pi/documents/Python/Fw_prj/Utility/fire-cloud-f2f21-firebase-adminsdk-7gyx2-bb48bdd146.json')
initialize_app(cred, {
    'databaseURL': 'https://fire-cloud-f2f21-default-rtdb.asia-southeast1.firebasedatabase.app/'
})

init_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
system_id = get_raspberry_pi_serial_number()

def initialize_system():
    ref = db.reference(f"Systems/{system_id}")
    existing_system = ref.get()
    if existing_system is not None:
        print(f"System {system_id} already exists in Firebase.")
        return

    current_time = init_date
    key = generate_unique_key()
    data = {
        'Key': key,
        'devices': {
            "ffff": { 
                "name": "System"
            }
        },
        'name': system_id
    }
    ref.set(data)
    print(f"System {system_id} initialized successfully")
    up_log(Log("ffff", config.SYSTEM_LOG))

def up_device(device_id, device_dict):
    ref = db.reference(f"Systems/{system_id}/devices/{device_id}")
    existing_device = ref.get()
    if existing_device is None:
        ref.set(device_dict)
        msg = f"Device {device_id} added to system {system_id} successfully"
    else:
        device_dict_without_name = {k: v for k, v in device_dict.items() if k != 'name'}
        ref.update(device_dict_without_name)
        msg = f"Device {device_id} updated in system {system_id} successfully"
    # print(msg)

def up_log(log):
    if isinstance(log, Log):
        current_time = datetime.now()
        init_datetime = datetime.strptime(init_date, "%Y-%m-%d %H:%M:%S")
        time_difference = current_time - init_datetime
        
        if time_difference > timedelta(days=config.HISTORY_DAYS_LIMIT):
            ref = db.reference(f"Systems/{system_id}/log")
            ref.delete() 
        
        current_time_str = current_time.strftime("%Y-%m-%d %H:%M:%S")
        ref = db.reference(f"Systems/{system_id}/log/{current_time_str}")
        ref.set({log.device_id: log.msg})

def get_device_name(device_id):
    ref = db.reference(f"Systems/{system_id}/devices/{device_id}/name")
    return ref.get()

def get_system_name():
    ref = db.reference(f"Systems/{system_id}/name")
    return ref.get()

def get_phone_numbers():
    ref = db.reference(f"Systems/{system_id}/phone")
    phone_numbers = ref.get()
    
    if phone_numbers is not None:
        phone_numbers = [phone for phone in phone_numbers if phone is not None]
    
    return phone_numbers

def upload_to_firebase(device):   
    device_id = str(device.name)
    device_data = {
        'name': f"id{device.name}",
        'temp': device.temp,
        'hum': device.hum,
        'air': device.air,        
        'fire': device.fire,
    }
    
    up_device(device_id, device_data)

def clear_file_contents(file_path):
    try:
        with open(file_path, 'w') as file:
            # Opening in write mode 'w' will clear the file contents
            file.write('')
        print(f'Successfully cleared contents of {file_path}')
    except Exception as e:
        print(f'Failed to clear contents of {file_path}. Reason: {e}')


def save_phone_numbers_to_file(phone_numbers, file_path):
    directory = os.path.dirname(file_path)
    
    # Delete all files in the directory before saving
    clear_file_contents(file_path)
    
    with open(file_path, 'w') as file:
        json.dump(phone_numbers, file, indent=4)

