class Device:
    def __init__(self,fire, hum, name, smoke, temp):
        self.name = name    
        self.fire = fire
        self.hum = hum      
        self.smoke = smoke
        self.temp = temp

    def to_dict(self):
        return {
            'name': self.name,
            'fire': self.fire,
            'hum': self.hum,            
            'smoke': self.smoke,
            'temp': self.temp
        }
