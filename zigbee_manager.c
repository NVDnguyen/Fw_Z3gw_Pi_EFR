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
  msg[3] = 112;
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
  if(emberAfGetPanId()!= 0x1345){
      count++;
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
void send_all_in_pan(){
    static uint8_t msg[5] = {0x00, 0x0A, 0x00, 123, 1};  // Message content
    broadcastMessage(&msg,sizeof(msg));

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
        // Handle error: buffer alloc ation failed
        emberAfCorePrintln("Handle error: buffer allocation failed");
        return;
    }

    // Send broadcast message
    status = emberSendBroadcast(EMBER_BROADCAST_ADDRESS, &apsFrame, 0, messageBuffer);
    if (status != EMBER_SUCCESS) {
        // Handle error: sending failed
        emberAfCorePrintln("Handle error: sending failed");
    }
}

void emberAfIncomingMessageCallback(EmberApsFrame *apsFrame,
                                    uint8_t messageLength,
                                    uint8_t *message)
{
    // Check if apsFrame and message are valid
    if (apsFrame == NULL || message == NULL) {
        emberAfCorePrintln("Invalid apsFrame or message");
        return;
    }

    // Check the cluster ID and endpoint to determine the type of message
    if (apsFrame->profileId == 0x0104 &&  // Home Automation profile ID
        apsFrame->clusterId == 0x000F &&  // Basic cluster ID
        apsFrame->destinationEndpoint == DESTINATION_ENDPOINT) {

        // Check the length of the message
        if (messageLength == 5) {
            uint8_t byte1 = message[0];
            uint8_t byte2 = message[1];
            uint8_t byte3 = message[2];
            uint8_t byte4 = message[3];
            uint8_t byte5 = message[4];

            // Process the bytes of the message as required
            emberAfCorePrintln("Received message:");
            emberAfCorePrintln("Byte 1: %d", byte1);
            emberAfCorePrintln("Byte 2: %d", byte2);
            emberAfCorePrintln("Byte 3: %d", byte3);
            emberAfCorePrintln("Byte 4: %d", byte4);
            emberAfCorePrintln("Byte 5: %d", byte5);
            //
            if(byte3 == 123){
                node_alarm = byte4;
            }

            // Perform actions based on the received data
            // For example: update status, send a response, etc.
        } else {
            emberAfCorePrintln("Unexpected message length: %d", messageLength);
        }
    } else {
        emberAfCorePrintln("Unsupported profile ID or cluster ID or endpoint");
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
