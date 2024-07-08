#include "sensor_data.h"

static analogio_analogin_obj_t analog_input;
static bool app_btn1_pressed = false;
static bool button_state;

void init_read_sensor() {
  smoke_adc_pin smoke_pin = {.port = gpioPortA, .number = 7};
// ADC init
  mcu_pin_obj_t pin = { .port = smoke_pin.port, .number = smoke_pin.number };
  analog_input_initialize(&analog_input, &pin);

  // Init temperature sensor.
  sl_sensor_rht_init();
  // Khởi tạo chân Buzzer
  GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 0);
  button_state = false;
}

void get_value_sensor(SensorData *data) {
  uint32_t h=0;
  uint32_t t=0;
  // Measure temperature; units are % and milli-Celsius.
  sl_status_t status = sl_sensor_rht_get(&h, &t);

  data->humidity =(uint8_t)(h/1000);
  data->temperature =(uint8_t)(t/1000);

  // Smoke
  data->smoke =get_voltage_ADC(&analog_input);
  // Process fire risk level
  process_risk_level(data);

}
void process_risk_level(SensorData *data){
  if (data->temperature > 50 || data->smoke > 50) {
         data->fire = 2; // High risk
     } else if ((data->temperature >= 40 && data->temperature <= 50) && data->smoke > 30) {
         data->fire = 1; // Maybe
     } else {
         data->fire = 0; // Normal
     }

  if (app_btn1_pressed) {
    button_state = !button_state;
  }
  if (button_state) {
    data->fire = 3;
  }

  if(data->fire > 1){
      GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 1);
  }else{
      GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 0);

  }
}

uint8_t convert_adc_to_percentage (uint16_t raw_value)
{
  uint16_t percentage = (raw_value / 65535.0) * 100.0;
  return percentage;
}

