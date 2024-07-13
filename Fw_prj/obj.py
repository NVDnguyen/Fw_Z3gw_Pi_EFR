class Device:
    def __init__(self, id, fire, hum, name, ch4, co, temp):
        self.id = id
        self.name = name    
        self.fire = fire
        self.hum = hum      
        self.ch4 = ch4  
        self.co = co   
        self.temp = temp

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'fire': self.fire,
            'hum': self.hum,            
            'ch4': self.ch4, 
            'co': self.co,  
            'temp': self.temp
        }

class Log:
    def __init__(self, device_id, msg):
        self.device_id = device_id    
        self.msg = msg

    def to_dict(self):
        return {
            'device_id': self.device_id,
            'msg': self.msg
        }
