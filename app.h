#ifndef APP_H
#define APP_H

#include "sensor_data.h"
#include "app_log.h"
#include "sl_sleeptimer.h"
#include "sl_simple_button_instances.h"

extern SensorData sensor;

void app_init(void);
void app_process_action(void);
void sl_button_on_change (const sl_button_t *handle);

#endif // APP_H
