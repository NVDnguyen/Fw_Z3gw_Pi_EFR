# Firebase configuration details
FIREBASE_CONFIG = {
    "apiKey": "AIzaSyAU5pfDocy-74rskYxODvo79jQ030aImA4",
    "authDomain": "fire-cloud-f2f21.firebaseapp.com",
    "databaseURL": "https://fire-cloud-f2f21-default-rtdb.asia-southeast1.firebasedatabase.app",
    "projectId": "fire-cloud-f2f21",
    "storageBucket": "fire-cloud-f2f21.appspot.com",
    "messagingSenderId": "533473486533",
    "appId": "1:533473486533:web:a221561b59117991e9b2ac",
    "measurementId": "G-EQTTGGR0FR"
}
START_NETWORK = [
    "plugin network-creator start 1",
    "plugin network-creator-security open-network"    
]
OPEN_NETWORK =["plugin network-creator-security open-network"]
RESET_NETWORK = [
    "network leave",
    "plugin network-creator start 1",
    "plugin network-creator-security open-network"
]
SEND_NODE_ACTION = [""]
MAX_LOG_SIZE_BYTES = 1024 
SERIAL_PORT = "/dev/ttyACM0"

SYSTEM_LOG = "Hệ thống đã được thiết lập"
RISK3_LOG = "Chông báo cháy đang bật"
RISK2_LOG = "Cảnh báo nguy cơ cháy nổ"
RISK1_LOG = "Phát hiện bất thường"
OPEN_NETWORK_LOG = "Hệ thống đang mở mạng"
RESET_NETWORK_LOG = "Hệ thống thiết lập lại"
ERROR_EXE_LOG = "Lỗi thiết lập mạng"