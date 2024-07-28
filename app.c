#include "app.h"
#include "app_log.h"
#include "sensor_data.h"
#include "zigbee_manager.h"

static SensorData sensor;
#define BUZZER_PORT gpioPortD  //13
#define BUZZER_PIN  2
bool on = false;
#define FIRE_PORT gpioPortC  // 8
#define FIRE_PIN  1

static int network_alarm;

void app_init(void) {
  init_read_sensor();

  // Initialize buzzer
  GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 0);

}

void app_process_action(void) {
  static int last_level = 0 ;
  get_value_sensor(&sensor);

  network_alarm = get_status_network_alarm();

  if(sensor.onAlarm == 1){
      sensor.level =3;
  }

  if(sensor.level > 1 || network_alarm > 1 ){
      on = true;
      GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 1);
  }else{
      on = false;
      GPIO_PinModeSet(BUZZER_PORT, BUZZER_PIN, gpioModePushPull, 0);
  }

  uint32_t current_time = sl_sleeptimer_tick_to_ms(sl_sleeptimer_get_tick_count());

  if(sensor.level != last_level){
  app_log_warning("network_alarm: %d\n", network_alarm);
  app_log_warning("Temp: %d | Hum: %d | Air: %d | Fire: %d | Level: %d | Button1 : %d | Reset : %d\n", sensor.temperature, sensor.humidity, sensor.air, sensor.fire, sensor.level, sensor.onAlarm,sensor.resetNetwork);
  send_all_in_pan(sensor.level);
  last_level = sensor.level;
  }
  //app_log_warning("Temp: %d | Hum: %d | Air: %d | Fire: %d | Level: %d | Button1 : %d | Reset : %d\n", sensor.temperature, sensor.humidity, sensor.air, sensor.fire, sensor.level, sensor.onAlarm,sensor.resetNetwork);


}

SensorData get_sensor_processed(){
  return sensor;
}

