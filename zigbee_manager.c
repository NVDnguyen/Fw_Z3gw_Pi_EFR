#include "app/framework/include/af.h"
#include "network-steering.h"
#include "network-formation.h"
#include "app.h"
#include "sensor_data.h"
#include "app_log.h"
#include "zigbee_manager.h"

static int node_alarm = 0 ;
SensorData data;
int count =0;
EmberEUI64 eui64;
static sl_zigbee_event_t sendMsgEvent;
static void sendMsgEventHandler(sl_zigbee_event_t *event);
// Function to send a message
void sendTestMessage(void) {
  EmberStatus status;
  EmberNodeId destination =  0x0000; // Node ID of Coordinator


  // Node ID forever
  emberAfGetEui64(eui64);

  data = get_sensor_processed();
  static uint8_t msg[10] ={0x00, 0x0A, 0x00};
  msg[1] +=1;
  msg[3] = 113;
  msg[4] = data.temperature;
  msg[5] = data.humidity;
  msg[6] = data.air;
  msg[7] = data.fire;
  msg[8] = data.level;

  // EmberApsFrame
  EmberApsFrame apsFrame;
  apsFrame.profileId = 0x0104; // Home Automation profile ID
  apsFrame.sourceEndpoint = SOURCE_ENDPOINT;
  apsFrame.destinationEndpoint = DESTINATION_ENDPOINT;
  apsFrame.clusterId = 0x000F; // Basic cluster ID
  apsFrame.options = EMBER_AF_DEFAULT_APS_OPTIONS;
  apsFrame.groupId = 0;
  apsFrame.sequence = 0;

  //printZigbeeInfo();
  // reset  network
  if(data.resetNetwork == 1){
      turn_off_reset_mode();
      emberLeaveNetwork();
      emberAfPluginNetworkSteeringStart();
  }
  // if not in network of coordinator
  if(emberAfGetPanId()!= 0xBF94){
      count++;
      emberAfCorePrintln("%u", emberAfGetPanId());
  }
  // reconnect coordinator
  if(count>4) {
      emberAfPluginNetworkSteeringStart(); // steering again
      count =0;
  }
  // send msg

  status = emberAfSendUnicast(EMBER_OUTGOING_DIRECT, destination, &apsFrame, 10 , msg);


  // check send possible
  if (status != EMBER_SUCCESS) {
   emberAfCorePrintln("Error_%d: %d",count,status);
   count++;
  }


//  app_log_warning("Temp: %d | Hum: %d | Air: %d | Fire: %d | Level: %d | Button1 : %d | Reset : %d\n", data.temperature, data.humidity, data.air, data.fire, data.level, data.onAlarm,data.resetNetwork);

}
void send_all_in_pan(uint8_t level) {
    uint8_t msg[2] = {0x00, level};  // Message containing level

    // Send broadcast message containing level to all nodes
    broadcastMessage(msg, sizeof(msg));
}
void broadcastMessage(uint8_t *message, uint8_t length) {
    EmberStatus status;
    EmberApsFrame apsFrame;
    EmberMessageBuffer messageBuffer;

    // Create APS frame
    apsFrame.profileId = 0x0000; // Use appropriate profile ID
    apsFrame.clusterId = 0x0000; // Use appropriate cluster ID
    apsFrame.sourceEndpoint = 0x01; // Use appropriate source endpoint
    apsFrame.destinationEndpoint = 0xFF; // Broadcast to all endpoints
    apsFrame.options = EMBER_APS_OPTION_RETRY | EMBER_APS_OPTION_ENABLE_ROUTE_DISCOVERY;

    // Allocate and fill message buffer
    messageBuffer = emberFillLinkedBuffers(message, length);
    if (messageBuffer == EMBER_NULL_MESSAGE_BUFFER) {
        emberAfCorePrintln("Handle error: buffer allocation failed");
        return;
    }

    // Send broadcast message
    int retryCount = 0;
    int MAX_RETRIES = 5;
    do {
        // Send broadcast message
        status = emberSendBroadcast(/*EMBER_BROADCAST_ADDRESS*/EMBER_RX_ON_WHEN_IDLE_BROADCAST_ADDRESS, &apsFrame, 0, messageBuffer);
        if (status == EMBER_NETWORK_BUSY) {
            emberAfCorePrintln("Network is busy, retrying...");
            retryCount++;
        } else if (status != EMBER_SUCCESS) {
            emberAfCorePrintln("Handle error: sending failed, status: 0x%X", status);
            break;
        }
    } while (status == EMBER_NETWORK_BUSY && retryCount < MAX_RETRIES);
}

void emberAfIncomingMessageCallback(EmberIncomingMessageType type, EmberApsFrame *apsFrame, EmberMessageBuffer message) {
    uint8_t messageLength = emberMessageBufferLength(message);
    uint8_t messageContent[messageLength];
    emberCopyFromLinkedBuffers(message, 0, messageContent, messageLength);

    if (apsFrame->profileId == 0x0000 && apsFrame->clusterId == 0x0000 && apsFrame->destinationEndpoint == 0xFF) {
        if (messageLength == 2) {
            uint8_t received_level = messageContent[1];
            if (received_level >= 0 && received_level <= 3) {
                node_alarm = received_level;
                emberAfCorePrintln("alarm arive");
            }
        }
    }
}


int get_status_network_alarm(){
  return node_alarm;
}
void emberAfMainInitCallback(void) {
  emberAfCorePrintln("Main init");
  sl_zigbee_event_init(&sendMsgEvent, sendMsgEventHandler);
  sl_zigbee_event_set_delay_ms(&sendMsgEvent, MSG_INTERVAL_MS);
  emberLeaveNetwork();
  emberAfPluginNetworkSteeringStart();
}


static void sendMsgEventHandler(sl_zigbee_event_t *event) {
  sendTestMessage();
  sl_zigbee_event_set_delay_ms(&sendMsgEvent, MSG_INTERVAL_MS);
}
