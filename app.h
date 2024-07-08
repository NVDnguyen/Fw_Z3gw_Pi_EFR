#ifndef APP_H
#define APP_H

#include "app_log.h"
#include "sensor_data.h"


void app_init(void);
void app_process_action(void);
SensorData get_sensor_processed();

#endif // APP_H
