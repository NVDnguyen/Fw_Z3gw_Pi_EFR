#ifndef SENSOR_DATA_H
#define SENSOR_DATA_H

#include <stdbool.h>
#ifdef SL_COMPONENT_CATALOG_PRESENT
#include "sl_component_catalog.h"
#endif // SL_COMPONENT_CATALOG_PRESENT
#ifdef SL_CATALOG_CLI_PRESENT
#include "sl_cli.h"
#endif // SL_CATALOG_CLI_PRESENT
#include "sl_sensor_rht.h"
#include "em_gpio.h"
#include "iadc.h"


// Fire, smoke, temp, hum, button, buzzer
typedef struct {
  uint8_t fire;
  uint8_t temperature;
  uint8_t humidity;
  uint8_t metan;
  uint8_t co;
  uint8_t onAlarm;
  uint8_t resetNetwork;
} SensorData;

typedef struct {
  GPIO_Port_TypeDef port;
  uint8_t number;
} smoke_adc_pin;


void init_read_sensor();
void get_value_sensor(SensorData *data);
uint8_t convert_adc_to_percentage (uint16_t raw_value);
void process_risk_level(SensorData *data);
int8_t read_button_state(GPIO_Port_TypeDef port, unsigned int pin);
void process_buttons(SensorData *data);
#endif // SENSOR_DATA_H
