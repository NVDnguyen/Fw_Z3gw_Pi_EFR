#include "sensor_data.h"
#include "sl_simple_button_instances.h"
#include "sl_simple_button.h"
// Define static global variables
static analogio_analogin_obj_t analog_input;
static smoke_adc_pin global_smoke_pin;
//static volatile bool app_btn1_pressed = false;
//static bool button_state;

void init_read_sensor(smoke_adc_pin *smoke_pin) {
  // Initialize global variables
  global_smoke_pin = *smoke_pin;
// ADC init
  mcu_pin_obj_t pin = { .port = global_smoke_pin.port, .number = global_smoke_pin.number };
  analog_input_initialize(&analog_input, &pin);

  // Init temperature sensor.
  sl_sensor_rht_init();
  // Khởi tạo chân Buzzer
//  GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 0);
//  button_state = false;
}

void get_value_sensor(SensorData *data) {
  uint32_t h=0;
  uint32_t t=0;

  // Measure temperature; units are % and milli-Celsius.
  sl_sensor_rht_get(&h, &t);

  data->humidity =(uint8_t)(h/1000);
  data->temperature =(uint8_t)(t/1000);

  // Smoke
  uint16_t adc_value = get_value_ADC(&analog_input);
  data->smoke =convert_adc_to_percentage(adc_value);
  // Process fire risk level
  if (data->temperature > 50 || data->smoke > 50) {
         data->fire = 2; // High risk
     } else if ((data->temperature >= 40 && data->temperature <= 50) && data->smoke > 30) {
         data->fire = 1; // Maybe
     } else {
         data->fire = 0; // Normal
     }

//  if (app_btn1_pressed) {
//    button_state = !button_state;
//  }
//  if (button_state) {
//    data->fire = 3;
//  }
//
//  if(data->fire > 1){
//      GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 1);
//  }else{
//      GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 0);
//
//  }
}
//void set_level_state (SensorData *data)
//{
//  float iadc_percentage = convert_adc_to_percentage (data->smoke_iadc_value);
//  if (warning_state)
//    {
//      data->level_state = 2;
//    }
//  else
//    {
//      if (data->temperature_value < 40)
//        {
//          data->level_state = 0;
//        }
//      else if (data->temperature_value > 40 || iadc_percentage > 30)
//        {
//          data->level_state = 1;
//        }
//      else if (data->temperature_value > 50 || iadc_percentage > 50)
//        {
//          data->level_state = 2;
//        }
//    }
//
//}

uint8_t convert_adc_to_percentage (uint16_t raw_value)
{
  uint8_t percentage = (raw_value / 65535.0) * 100.0;
  return percentage;
}
//void sl_button_on_change (const sl_button_t *handle)
//{
//  if (sl_button_get_state (handle) == SL_SIMPLE_BUTTON_PRESSED){
//      // Button pressed.
//      if (&sl_button_btn1 == handle) {
//          app_btn1_pressed = true;
//      }
//    } // Button released.
//    else if (sl_button_get_state(handle) == SL_SIMPLE_BUTTON_RELEASED) {
//      if (&sl_button_btn1 == handle) {
//          app_btn1_pressed = false;
//          printf("released");
//      }
//    }
//
//
//
//}

