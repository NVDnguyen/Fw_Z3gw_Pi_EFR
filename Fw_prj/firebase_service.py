from obj import Log
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from datetime import datetime
from Utility.gen_system import get_raspberry_pi_serial_number, generate_unique_key
import config

# Initialize Firebase Admin
cred = credentials.Certificate('/home/pi/documents/Python/Fw_prj/Utility/fire-cloud-f2f21-firebase-adminsdk-7gyx2-29f678785a.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://fire-cloud-f2f21-default-rtdb.asia-southeast1.firebasedatabase.app/'
})

# Get the system id from your utility module
system_id = get_raspberry_pi_serial_number()

def initialize_system():
    ref = db.reference(f"Systems/{system_id}")
    existing_system = ref.get()
    if existing_system is not None:
        print(f"System {system_id} already exists in Firebase.")
        return

    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    key = generate_unique_key()
    data = {
        'Key': key,
        'devices': {
            "ffff" : { 
                "name" :"System"
                }
            },
        'name': system_id
    }
    ref.set(data)
    print(f"System {system_id} initialized successfully")
    up_log(Log("ffff",config.SYSTEM_LOG))

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
    #print(msg)


def up_log(log):
    if isinstance(log, Log):        
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        ref = db.reference(f"Systems/{system_id}/log/{current_time}")
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
    
    # Filter out any null values in the phone numbers list
    if phone_numbers is not None:
        phone_numbers = [phone for phone in phone_numbers if phone is not None]
    
    return phone_numbers

def upload_to_firebase(device):   
    device_id = str(device.name)
    device_data = {
        'name': f"id{device.name}",
        'temp': device.temp,
        'hum': device.hum,
        'gas': device.ch4,
        'co' : device.co,
        'fire': device.fire,
    }
    
    up_device(device_id, device_data)
    



# import pyrebase
# from datetime import datetime
# from Utility.gen_system import get_raspberry_pi_serial_number, generate_unique_key
# import config
# # Initialize Firebase
# firebase = pyrebase.initialize_app(config.FIREBASE_CONFIG)
# db = firebase.database()
# system_id = get_raspberry_pi_serial_number()

# def initialize_system():
#     existing_system = db.child("Systems").child(system_id).get().val()
#     if existing_system is not None:
#         print(f"System {system_id} already exists in Firebase.")
#         return

#     current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
#     key = generate_unique_key()
#     data = {
#         'Key': key,
#         'admin': '',
#         'devices': {},
#         'name': system_id
#     }
#     db.child("Systems").child(system_id).set(data)
#     msg = f"System {system_id} initialized successfully"
#     device_id = "1"
#     up_log(system_id, db, device_id, msg)

# def up_device(device_id, device_dict):
#     existing_device = db.child("Systems").child(system_id).child("devices").child(device_id).get().val()
#     if existing_device is None:
#         db.child("Systems").child(system_id).child("devices").child(device_id).set(device_dict)
#         msg = f"Device {device_id} added to system {system_id} successfully"
#         print(msg)
#     else:
#         device_dict_without_name = {k: v for k, v in device_dict.items() if k != 'name'}
#         db.child("Systems").child(system_id).child("devices").child(device_id).update(device_dict_without_name)
#         print(f"Device {device_id} updated in system {system_id} successfully")
#     up_log(system_id, db, device_id, msg)

# def up_log(device_id, msg):
#     current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
#     log_entry = {
#         current_time: {
#             device_id: msg
#         }
#     }
#     db.child("Systems").child(system_id).child("log").update(log_entry)

# def get_device_name(device_id):
#     return db.child("Systems").child(system_id).child("devices").child(device_id).child("name").get().val()

# def get_system_name():
#     return db.child("Systems").child(system_id).child("name").get().val()


# def upload_to_firebase(device):   
#     device_id = str(device.name)
#     device_data = {
#         'name': "id" + str(device.name),
#         'temp': device.temp,
#         'hum': device.hum,
#         'smoke': device.smoke,
#         'fire': device.fire,
#     }
#     up_device(system_id, db, device_id, device_data)
