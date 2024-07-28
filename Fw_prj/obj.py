class Device:
    def __init__(self, id, fire, hum, name, air, temp,level):
        self.id = id
        self.name = name    
        self.fire = fire
        self.hum = hum      
        self.air =air  
        self.temp = temp
        self.level = level

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'fire': self.fire,
            'hum': self.hum,            
            'air': self.air,              
            'temp': self.temp,
            'level':self.level
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
