#ifndef IADC_H
#define IADC_H

#include <stdint.h>
#include <stdbool.h>
#include "em_iadc.h"
#include "em_gpio.h"
#include "em_cmu.h"

// Set the ADC clock to 10 MHz
#define CLK_SRC_ADC_FREQ 20000000  // Source ADC Clock
#define CLK_ADC_FREQ 10000000      // ADC Clock - 10 MHz maximum in normal mode
#define ADC_RESOLUTION 4095        // 12-bit ADC
#define VREF 3.3                   // Reference voltage
#define NUM_INPUTS 8               // Number of scan channels

extern volatile uint16_t scan_result[NUM_INPUTS];
extern volatile uint8_t scan_flag;
extern IADC_ScanTable_t init_scan_table;

typedef struct {
    const GPIO_Port_TypeDef port;
    uint8_t number;
} mcu_pin_obj_t;

typedef struct {
    const mcu_pin_obj_t *pin;
    uint8_t id;
} analogio_analogin_obj_t;

// Function prototypes
void analog_input_initialize(analogio_analogin_obj_t *self, const mcu_pin_obj_t *pin);
bool analog_input_is_deinitialized(analogio_analogin_obj_t *self);
void analog_input_deinitialize(analogio_analogin_obj_t *self);
void IADC_IRQHandler(void);
uint16_t get_value_ADC(analogio_analogin_obj_t *self);
float get_voltage_ADC(analogio_analogin_obj_t *self);

#endif // IADC_H
