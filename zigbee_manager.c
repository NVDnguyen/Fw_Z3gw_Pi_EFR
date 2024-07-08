#include "app/framework/include/af.h"
#include "network-steering.h"
#include "network-formation.h"
#include "app.h"
#include "sensor_data.h"
#include "app_log.h"

#define SOURCE_ENDPOINT 1
#define DESTINATION_ENDPOINT 1
#define MSG_INTERVAL_MS 5000
#define EMBER_AF_DOXYGEN_CLI_COMMAND_BUILD_SEND_MSG_RAW


static sl_zigbee_event_t sendMsgEvent;
static void sendMsgEventHandler(sl_zigbee_event_t *event);
SensorData data;
int count =0;
// Function to send a message
void sendTestMessage(void) {
  EmberStatus status;
  EmberNodeId destination =  0x0000; // Node ID of Coordinator
  EmberNodeId source = emberAfGetNodeId(); // My ID
  uint16_t message[10];

  data = get_sensor_processed();
  app_log_warning("Temp: %d | Hum: %d | Smoke: %d | Level: %d \n", data.temperature, data.humidity, data.smoke, data.fire);

  static uint8_t msg[10] ={0x00, 0x0A, 0x00};
  msg[1] +=1;
  msg[3] = (uint8_t)(source >> 8); // split address
  msg[4] = (uint8_t)source;
  msg[5] = data.temperature;
  msg[6] = data.humidity;
  msg[7] = data.smoke;
  msg[8] = data.fire;

  // EmberApsFrame
  EmberApsFrame apsFrame;
  apsFrame.profileId = 0x0104; // Home Automation profile ID
  apsFrame.sourceEndpoint = SOURCE_ENDPOINT;
  apsFrame.destinationEndpoint = DESTINATION_ENDPOINT;
  apsFrame.clusterId = 0x000F; // Basic cluster ID
  apsFrame.options = EMBER_AF_DEFAULT_APS_OPTIONS;
  apsFrame.groupId = 0;
  apsFrame.sequence = 0;

  // Check if the device is on a network
  if (emberNetworkState() != EMBER_JOINED_NETWORK) {
    emberAfCorePrintln("Error: Device is not on a network");
  }

  // Send Unicast to destination
  status = emberAfSendUnicast(EMBER_OUTGOING_DIRECT, destination, &apsFrame, 10 , msg);

  // Check network possible
  if (status != EMBER_SUCCESS) {
    emberAfCorePrintln("Error_%d: %d",count,status);
    count++;
    if(count>5){
      status = emberLeaveNetwork(); // leave available network
      if(status == EMBER_SUCCESS){
        status = emberAfPluginNetworkSteeringStart(); // steering again
        if(status == EMBER_SUCCESS){
          count =0;
        }
      }else{
          emberAfCorePrintln("Hey: Cannot leave network");
      }
    }
  }

  if (status != EMBER_SUCCESS) {
    emberAfCorePrintln("Error: %d", status);
  } else {
    emberAfCorePrintln("Message sent: %s", message);
  }
}


void emberAfMainInitCallback(void) {
  emberAfCorePrintln("Main init");
  sl_zigbee_event_init(&sendMsgEvent, sendMsgEventHandler);
  sl_zigbee_event_set_delay_ms(&sendMsgEvent, MSG_INTERVAL_MS);
}


static void sendMsgEventHandler(sl_zigbee_event_t *event) {
  sendTestMessage();
  sl_zigbee_event_set_delay_ms(&sendMsgEvent, MSG_INTERVAL_MS);
}

