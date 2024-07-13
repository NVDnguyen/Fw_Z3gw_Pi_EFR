#include "app.h"
#include "app_log.h"
//#include "sl_simple_button_instances.h"
//#include "sl_simple_button.h"
#include "sensor_data.h"

static SensorData sensor;
#define BUZZER_PORT gpioPortD  //13
#define BUZZER_PIN  2
bool on = false;

void app_init(void) {
  init_read_sensor();

  // Initialize buzzer
  GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 0);

}

void app_process_action(void) {

  get_value_sensor(&sensor);

  if(sensor.onAlarm == 1){
      sensor.fire =3;
  }
  if(sensor.fire > 1){
      on = true;
      GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 1);
  }else{
      on = false;
      GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 0);
  }
 //app_log_warning("Temp: %d | Hum: %d | Metan: %d |Co: %d | Level: %d | Button1 : %d | Reset : %d | Speak: %d\n", sensor.temperature, sensor.humidity, sensor.metan,sensor.co, sensor.fire, sensor.onAlarm,sensor.resetNetwork,on);
}

SensorData get_sensor_processed(){
  return sensor;
}
