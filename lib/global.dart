library hackstar.global;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:humanitarian_icons/humanitarian_icons.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttServerClient client = MqttServerClient('broker.hivemq.com', '');
MqttClientPayloadBuilder payloadBuilder = MqttClientPayloadBuilder();
String mqttTopic = "Avana/Search";
bool callCancelled = false;

late Position currentLoc;
String receiverName = "";
String receiverPhone = "";

String callerName = "";

bool receivingCall = false;

String personName = "";
String personAge = "";
bool isSpeciallyAbled = false;
bool isHelpNeeded = false;
bool isVolunteering = false;
String phoneNumber = "";

List<String> reasons = [
  "Emergency",
  "Mobility",
  "Vehicle Breakdown",
  "EV Out of Charge",
  "General"
];
List<String> reasonDescription = [
  "Threat to life, health etc",
  "Wheelchair, crutch assistance etc",
  "Flat tire, engine not starting, ran out of fuel etc",
  "Get to a charging point",
  "Non Specific help required"
];
List<Icon> reasonIcons = [
  const Icon(
    HumanitarianIcons.clinic,
    size: 30,
  ),
  Icon(
    HumanitarianIcons.people_with_physical_impairments,
    size: 30,
    color: Colors.grey[700],
  ),
  Icon(
    Icons.car_repair,
    size: 30,
    color: Colors.grey[700],
  ),
  Icon(
    Icons.electric_car,
    size: 30,
    color: Colors.grey[700],
  ),
  Icon(
    Icons.assistant,
    size: 30,
    color: Colors.grey[700],
  ),
];
