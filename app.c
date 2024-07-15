#include "app.h"
#include "app_log.h"
#include "sensor_data.h"

static SensorData sensor;
#define BUZZER_PORT gpioPortD  //13
#define BUZZER_PIN  2
bool on = false;
#define FIRE_PORT gpioPortC  // 8
#define FIRE_PIN  1
void app_init(void) {
  init_read_sensor();

  // Initialize buzzer
  GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 0);

}

void app_process_action(void) {

  get_value_sensor(&sensor);


  if(sensor.onAlarm == 1){
      sensor.level =3;
  }
  if(sensor.level > 1){
      on = true;
      GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 1);
  }else{
      on = false;
      GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 0);
  }
  app_log_warning("Temp: %d | Hum: %d | Air: %d | Fire: %d | Level: %d | Button1 : %d | Reset : %d\n", sensor.temperature, sensor.humidity, sensor.air, sensor.fire, sensor.level, sensor.onAlarm,sensor.resetNetwork);


}

SensorData get_sensor_processed(){
  return sensor;
}
