#include "sensor_data.h"

#define BUTTON_PRESSED 1
#define BUTTON_RELEASED 0
#define BUTTON0_PORT gpioPortC// button control alarm   //4
#define BUTTON0_PIN  3
#define BUTTON1_PORT gpioPortB // button reset network // bt0
#define BUTTON1_PIN  2
#define FIRE_PORT gpioPortC  // 8
#define FIRE_PIN  1



//#define RL 1.0 // Load resistance in kilo-ohms
//#define RO 4.0 // Ro value in kilo-ohms (calibrated in clean air)
//#define Vc 5.0  // Supply voltage
//#define ADC_RESOLUTION 4095.0 // ADC resolution (12-bit ADC)

smoke_adc_pin mq2_pin = {.port = gpioPortA, .number = 7}; // mq2 // 10
//smoke_adc_pin co_pin = {.port = gpioPortC, .number = 1}; // mq7  // 8




static analogio_analogin_obj_t metan_input;

uint8_t alarm_state = false;
uint8_t reset_state = false;


void init_read_sensor() {
    // ADC init
    mcu_pin_obj_t pin = { .port = mq2_pin.port, .number = mq2_pin.number };
    analog_input_initialize(&metan_input, &pin);
//    mcu_pin_obj_t pin1 = { .port = co_pin.port, .number = co_pin.number };
//    analog_input_initialize(&co_input, &pin1);

    // Init temperature sensor
    sl_sensor_rht_init();

    // Configure GPIO as input with pull-up
    CMU_ClockEnable(cmuClock_GPIO, true);
    GPIO_PinModeSet(BUTTON0_PORT, BUTTON0_PIN, gpioModeInputPull, 1);
    GPIO_PinModeSet(BUTTON1_PORT, BUTTON1_PIN, gpioModeInputPull, 1);
    GPIO_PinModeSet(FIRE_PORT, FIRE_PIN, gpioModeInputPull, 1);
}

void get_value_sensor(SensorData *data) {
    uint32_t h = 0, t = 0;

    // Measure temperature; units are % and milli-Celsius
    sl_status_t status = sl_sensor_rht_get(&h, &t);
    if (status == SL_STATUS_OK) {
        data->humidity = (uint8_t)(h / 1000);
        data->temperature = (uint8_t)(t / 1000);
    }

    data->air = get_voltage_ADC(&mq2_pin);
    data->fire = GPIO_PinInGet(FIRE_PORT,FIRE_PIN)==1?0:1;



    // Process buttons
    process_buttons(data);

    // Process fire risk level
    process_risk_level(data);
}

void process_buttons(SensorData *data) {
    static int8_t last_button0_state = BUTTON_RELEASED;
    static int8_t last_button1_state = BUTTON_RELEASED;

    int8_t button0_state = read_button_state(BUTTON0_PORT, BUTTON0_PIN);
    int8_t button1_state = read_button_state(BUTTON1_PORT, BUTTON1_PIN);

    if (button0_state == BUTTON_PRESSED && last_button0_state == BUTTON_RELEASED) {
        alarm_state = !alarm_state;
    }
    last_button0_state = button0_state;
    data->onAlarm = alarm_state;

    if (button1_state == BUTTON_PRESSED && last_button1_state == BUTTON_RELEASED) {
        reset_state = !reset_state;
    }
    last_button1_state = button1_state;
    data->resetNetwork = reset_state;
}

void turn_off_reset_mode(){
  reset_state = !reset_state;
}

void process_risk_level(SensorData *data) {
    if (data->fire == 1) {
        // High risk: fire detected
        data->level = 3;
    } else if (data->temperature >= 60 && data->air >= 11) {
        // High risk: no fire, very high temperature and air not good
        data->level = 3;
    } else if (data->air >= 25) {
        // Medium risk: air very not good
        data->level = 2;
    } else if (data->temperature >= 50 && data->air >= 15) {
        // Medium risk: no fire, high temperature and air not good
        data->level = 2;
    } else if (data->air >= 15) {
        // Low risk: air not good
        data->level = 1;
    } else {
        // No risk: normal conditions
        data->level = 0;
    }
}

int8_t read_button_state(GPIO_Port_TypeDef port, unsigned int pin) {
    // Read the actual state of the pin
    int8_t pin_state = GPIO_PinInGet(port, pin);

    // Apply debounce filter (simple delay)
    uint32_t debounce_time = 2000;
    for (uint32_t i = 0; i < debounce_time; i++);

    // Read the pin state again
    int8_t debounced_pin_state = GPIO_PinInGet(port, pin);

    // If the pin state has not changed, return the debounced pin state
    if (pin_state == debounced_pin_state) {
        return (debounced_pin_state == 0) ? BUTTON_PRESSED : BUTTON_RELEASED;
    } else {
        return -1;
    }
}

