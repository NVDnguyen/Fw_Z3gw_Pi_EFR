#include "sensor_data.h"

#define BUTTON_PRESSED 1
#define BUTTON_RELEASED 0
#define BUTTON0_PORT gpioPortC// button control alarm   //4
#define BUTTON0_PIN  3
#define BUTTON1_PORT gpioPortB // button reset network // bt0
#define BUTTON1_PIN  2

#define TEMP_THRESHOLD_HIGH 75 // High temperature threshold in Celsius
#define TEMP_THRESHOLD_MEDIUM 50 // Medium temperature threshold in Celsius
#define SMOKE_THRESHOLD_HIGH 200 // High smoke threshold in ppm
#define SMOKE_THRESHOLD_MEDIUM 100 // Medium smoke threshold in ppm
#define CO_THRESHOLD_HIGH 150 // High CO threshold in ppm
#define CO_THRESHOLD_MEDIUM 50 // Medium CO threshold in ppm



smoke_adc_pin metan_pin = {.port = gpioPortA, .number = 7}; // mq2 // 10
smoke_adc_pin co_pin = {.port = gpioPortC, .number = 1}; // mq7  // 8




static analogio_analogin_obj_t metan_input;
static analogio_analogin_obj_t co_input;

uint8_t alarm_state = false;

void init_read_sensor() {
    // ADC init
    mcu_pin_obj_t pin = { .port = metan_pin.port, .number = metan_pin.number };
    analog_input_initialize(&metan_input, &pin);
    mcu_pin_obj_t pin1 = { .port = co_pin.port, .number = co_pin.number };
    analog_input_initialize(&co_input, &pin1);

    // Init temperature sensor
    sl_sensor_rht_init();

    // Configure GPIO as input with pull-up
    CMU_ClockEnable(cmuClock_GPIO, true);
    GPIO_PinModeSet(BUTTON0_PORT, BUTTON0_PIN, gpioModeInputPull, 1);
    GPIO_PinModeSet(BUTTON1_PORT, BUTTON1_PIN, gpioModeInputPull, 1);
}

void get_value_sensor(SensorData *data) {
    uint32_t h = 0, t = 0;

    // Measure temperature; units are % and milli-Celsius
    sl_status_t status = sl_sensor_rht_get(&h, &t);
    if (status == SL_STATUS_OK) {
        data->humidity = (uint8_t)(h / 1000);
        data->temperature = (uint8_t)(t / 1000);
    }

    //
//    uint8_t metan_vt = (uint8_t) get_voltage_ADC(&metan_input); //mq2
//    uint8_t co_vt = (uint8_t) get_voltage_ADC(&co_input); // mq7
//    calculate_gas_concentration(metan_vt, co_vt, &data->metan, &data->co);
    data->co = get_voltage_ADC(&co_input);
    data->metan = get_voltage_ADC(&metan_input);


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
        data->resetNetwork = BUTTON_PRESSED;
    } else {
        data->resetNetwork = BUTTON_RELEASED;
    }
    last_button1_state = button1_state;
}


void process_risk_level(SensorData *data) {
//    if (data->temperature > TEMP_THRESHOLD_HIGH || data->metan > SMOKE_THRESHOLD_HIGH || data->co > CO_THRESHOLD_HIGH) {
//        data->fire = 2; // High risk
//    } else if ((data->temperature >= TEMP_THRESHOLD_MEDIUM && data->temperature <= TEMP_THRESHOLD_HIGH) &&
//               (data->metan > SMOKE_THRESHOLD_MEDIUM || data->co > CO_THRESHOLD_MEDIUM)) {
//        data->fire = 1; // Medium risk
//    } else {
//        data->fire = 0; // Low risk
//    }
   if(data->temperature > 50 || data->metan >40 || data->co > 40){
       data->fire =3;
   }else if(data->temperature > 50 || data->metan >30 || data->co > 20){
       data->fire =2;

   }else if(data->temperature > 40 || data->metan >22 || data->co > 22){
       data->fire =1;

   }
   else{
       data->fire =0;
   }
}

void calculate_gas_concentration(uint16_t metan_adc, uint16_t co_adc, uint8_t *metan_conc, uint8_t *co_conc) {
    float Vin = 5.0;
    float adc_max = 4095.0; // Maximum ADC value for 12-bit ADC

    // Constants for MQ-2 (Methane)
    float a_metan = 2.0;
    float b_metan = -2.5;

    // Constants for MQ-7 (CO)
    float a_co = 1.0;
    float b_co = -1.5;

    // Convert ADC value to voltage
    float Vout_metan = (metan_adc / adc_max) * Vin;
    float Vout_co = (co_adc / adc_max) * Vin;

    // Calculate methane concentration
    *metan_conc = (uint8_t)(a_metan * pow((Vout_metan / Vin), b_metan));

    // Calculate CO concentration
    *co_conc = (uint8_t)(a_co * pow((Vout_co / Vin), b_co));
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
