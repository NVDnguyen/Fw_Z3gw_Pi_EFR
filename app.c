#include "app.h"
#include "app_log.h"
#include "sl_simple_button_instances.h"
#include "sl_simple_button.h"

// Định nghĩa biến sensor
SensorData sensor;

static volatile bool app_btn1_pressed = false;
static bool button_state;

void app_init(void) {
  // Khởi tạo chân cảm biến
  smoke_adc_pin smoke_pin = {.port = gpioPortA, .number = 7};
  init_read_sensor(&smoke_pin);

//  // Khởi tạo chân Buzzer
  GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 0);
  button_state = false;
}

void app_process_action(void) {
  // Đọc dữ liệu cảm biến
  get_value_sensor(&sensor);
  //sl_sleeptimer_delay_millisecond(100);
  if (app_btn1_pressed) {
    button_state = !button_state;
    app_btn1_pressed=false;
  }
  if (button_state) {
    sensor.fire = 3;
  }

  if(sensor.fire > 1){
      GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 1);
  }else{
      GPIO_PinModeSet(gpioPortD, 2, gpioModePushPull, 0);
  }
//   app_log_warning("Temp: %d | Hum: %d | Smoke: %d | Level: %d | Alarm : %d\n", sensor.temperature, sensor.humidity, sensor.smoke, sensor.fire, button_state);
}
void sl_button_on_change (const sl_button_t *handle)
{
  if (sl_button_get_state (handle) == SL_SIMPLE_BUTTON_PRESSED){
      // Button pressed.
      if (&sl_button_btn1 == handle) {
          app_btn1_pressed = true;
      }
    } // Button released.
  else if (sl_button_get_state(handle) == SL_SIMPLE_BUTTON_RELEASED) {
    if (&sl_button_btn1 == handle) {
        app_btn1_pressed = false;
        printf("released");
    }
  }
}
