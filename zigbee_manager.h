#ifndef ZIGBEE_MANAGER_H
#define ZIGBEE_MANAGER_H

#define SOURCE_ENDPOINT 1
#define DESTINATION_ENDPOINT 1
#define MSG_INTERVAL_MS 2000
#define EMBER_AF_DOXYGEN_CLI_COMMAND_BUILD_SEND_MSG_RAW




void sendTestMessage(void);
void send_all_in_pan();

int get_status_network_alarm();
void emberAfMainInitCallback(void) ;
void broadcastMessage(uint8_t *message, uint8_t length);

#endif
