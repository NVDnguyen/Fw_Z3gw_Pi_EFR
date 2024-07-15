#include "app/framework/include/af.h"
#include "network-steering.h"
#include "network-formation.h"
#include "app.h"
#include "sensor_data.h"
#include "app_log.h"


#define SOURCE_ENDPOINT 1
#define DESTINATION_ENDPOINT 1
#define MSG_INTERVAL_MS 2000
#define EMBER_AF_DOXYGEN_CLI_COMMAND_BUILD_SEND_MSG_RAW


static sl_zigbee_event_t sendMsgEvent;
static void sendMsgEventHandler(sl_zigbee_event_t *event);
SensorData data;
int count =0;
EmberEUI64 eui64;
// Function to send a message
void sendTestMessage(void) {
//  EmberStatus status;
//  EmberNodeId destination =  0x0000; // Node ID of Coordinator
//
//
//  // Node ID forever
//  emberAfGetEui64(eui64);
//
//  data = get_sensor_processed();
//  static uint8_t msg[10] ={0x00, 0x0A, 0x00};
//  msg[1] +=1;
//  msg[3] = 112;
//  msg[4] = data.temperature;
//  msg[5] = data.humidity;
//  msg[6] = data.air;
//  msg[7] = data.fire;
//  msg[8] = data.level;
//
//  // EmberApsFrame
//  EmberApsFrame apsFrame;
//  apsFrame.profileId = 0x0104; // Home Automation profile ID
//  apsFrame.sourceEndpoint = SOURCE_ENDPOINT;
//  apsFrame.destinationEndpoint = DESTINATION_ENDPOINT;
//  apsFrame.clusterId = 0x000F; // Basic cluster ID
//  apsFrame.options = EMBER_AF_DEFAULT_APS_OPTIONS;
//  apsFrame.groupId = 0;
//  apsFrame.sequence = 0;
//
//  //printZigbeeInfo();
//  // reset  network
//  if(data.resetNetwork == 1){
//      turn_off_reset_mode();
//      emberLeaveNetwork();
//      emberAfPluginNetworkSteeringStart();
//  }
//  // if not in network of coordinator
//  if(emberAfGetPanId()!= 0x1345){
//      count++;
//  }
//  // reconnect coordinator
//  if(count>4) {
//      emberAfPluginNetworkSteeringStart(); // steering again
//      count =0;
//  }
//  // send msg
//  status = emberAfSendUnicast(EMBER_OUTGOING_DIRECT, destination, &apsFrame, 10 , msg);
//  // check send possible
//  if (status != EMBER_SUCCESS) {
//   emberAfCorePrintln("Error_%d: %d",count,status);
//   count++;
//  }
  //app_log_warning("Temp: %d | Hum: %d | Air: %d | Fire: %d | Level: %d | Button1 : %d | Reset : %d\n", data.temperature, data.humidity, data.air, data.fire, data.level, data.onAlarm,data.resetNetwork);




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
void printZigbeeInfo(void)
{
  EmberNodeId nodeId = emberAfGetNodeId();
  EmberPanId panId = emberAfGetPanId();
  EmberNetworkStatus networkStatus = emberAfNetworkState();
  uint8_t radioChannel = emberAfGetRadioChannel();
  uint8_t bindingIndex = emberAfGetBindingIndex();
  uint8_t stackProfile = emberAfGetStackProfile();
  uint8_t addressIndex = emberAfGetAddressIndex();

  emberAfCorePrintln("Node ID: %d", nodeId);
  emberAfCorePrintln("PAN ID: %d", panId);
  emberAfCorePrintln("Network Status: %d", networkStatus);
  emberAfCorePrintln("Radio Channel: %d", radioChannel);
  emberAfCorePrintln("Binding Index: %d", bindingIndex);
  emberAfCorePrintln("Stack Profile: %d", stackProfile);
  emberAfCorePrintln("Address Index: %d", addressIndex);

  uint8_t endpointCount = emberAfEndpointCount();
  emberAfCorePrintln("Endpoint Count: %d", endpointCount);

//  for (uint8_t i = 0; i < endpointCount; i++) {
//    uint8_t endpoint = emberGetEndpoint(i);
//    emberAfCorePrintln("Endpoint %d: %d", i, endpoint);
//
//    EmberEndpointDescription endpointDescription;
//    if (emberGetEndpointDescription(endpoint, &endpointDescription)) {
//      emberAfCorePrintln("  Device ID: 0x%2X", endpointDescription.deviceId);
//      emberAfCorePrintln("  Profile ID: 0x%2X", endpointDescription.profileId);
//      emberAfCorePrintln("  Device Version: 0x%X", endpointDescription.deviceVersion);
//      emberAfCorePrintln("  Input Cluster Count: %d", endpointDescription.inputClusterCount);
//      emberAfCorePrintln("  Output Cluster Count: %d", endpointDescription.outputClusterCount);
//
//      for (uint8_t j = 0; j < endpointDescription.inputClusterCount; j++) {
//        uint16_t clusterId = emberGetEndpointCluster(endpoint, EMBER_INPUT_CLUSTER_LIST, j);
//        emberAfCorePrintln("    Input Cluster %d: 0x%4X", j, clusterId);
//      }
//
//      for (uint8_t j = 0; j < endpointDescription.outputClusterCount; j++) {
//        uint16_t clusterId = emberGetEndpointCluster(endpoint, EMBER_OUTPUT_CLUSTER_LIST, j);
//        emberAfCorePrintln("    Output Cluster %d: 0x%4X", j, clusterId);
//      }
//    } else {
//      emberAfCorePrintln("  Failed to get endpoint description for endpoint %d", endpoint);
//    }
//  }
}


