import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avana/call_receive.dart';
import 'package:avana/personal_details.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:path_provider/path_provider.dart';
import 'call_sent.dart';
import 'global.dart' as global;

class InitiateScreen extends StatefulWidget {
  const InitiateScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<InitiateScreen> createState() => _InitiateScreen();
}

class _InitiateScreen extends State<InitiateScreen> {
  CallSentScreen callSentScreen = const CallSentScreen(index: 0, alert: false);

  @override
  void initState() {
    super.initState();
    Timer reconnect = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (global.client.connectionState != MqttConnectionState.connected) {
        connectMQTT();
      }
      log("Timer Ticking - Connection Status: " +
          global.client.connectionState.toString() +
          "\n User's Name: " +
          global.personName +
          "User's Phone: " +
          global.phoneNumber);
      if (global.callCancelled == true) {
        cancelCall();
      }
    });
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.\nPlease go to settings to grant location permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future connectMQTT() async {
    global.client.setProtocolV311();
    global.client.onDisconnected = onDisconnected;
    global.client.onConnected = onConnected;
    global.client.onSubscribed = onSubscribed;
    try {
      final connMess = MqttConnectMessage()
          //.withClientIdentifier('Mqtt_MEGA')
          .withWillTopic('Will_Topic')
          .withWillMessage('My Will message')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      log('Connecting to Server...');
      global.client.connectionMessage = connMess;

      try {
        await global.client.connect();
      } on NoConnectionException catch (e) {
        log('MQTT Server exception - $e');
        // Fluttertoast.showToast(
        //   msg:
        //       "Could not connect to the server.\nCheck your connection and try again.",
        //   backgroundColor: Colors.black,
        // );
      } on SocketException catch (e) {
        log('MQTT Socket exception - $e');
        // Fluttertoast.showToast(
        //   msg:
        //       "Could not connect to the socket.\nCheck your connection and try again.",
        //   backgroundColor: Colors.black,
        // );
      }

      if (global.client.connectionStatus!.state ==
          MqttConnectionState.connected) {
        log('MQTT client connected');
      } else {
        log('MQTT client connection failed, disconnecting, status is ${global.client.connectionStatus}');
        // Fluttertoast.showToast(
        //   msg:
        //       "Could not connect to the client.\nCheck your connection and try again.",
        //   backgroundColor: Colors.black,
        // );
      }

      log('MQTT Subscribing to Status');

      global.client.subscribe(global.mqttTopic, MqttQos.atMostOnce);
    } catch (e) {
      // Fluttertoast.showToast(
      //   msg:
      //       "Could not connect to the network.\nCheck your connection and try again.",
      //   backgroundColor: Colors.black,
      // );
    }
  }

  void onSubscribed(String topic) {
    log('MQTT Subscription confirmed for topic $topic');

    global.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      parseMessage(pt);

      log('MQTT Topic is: ${c[0].topic}, Payload is: $pt');
    });
  }

  void parseMessage(String message) {
    if (message.split(':')[1] != global.personName) {
      if (message.split(":").length == 2 &&
          message.startsWith("CANCEL") &&
          message.split(":")[1] == global.callerName) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    if (message.split(":").length == 4 && message.startsWith("ACK")) {
      if (message.split(":")[3] == global.personName &&
          global.receiverName == "") {
        global.receiverName = message.split(":")[1];
        global.receiverPhone = message.split(":")[2];
      }
    }

    if (message.split(":").length == 5 &&
        global.receivingCall == false &&
        message.split(':')[1] != global.personName) {
      var index = global.reasons.indexOf(message.split(":")[4]);
      global.callerName = message.split(":")[1];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallReceiveScreen(
            personName: message.split(":")[1],
            phoneNumber: message.split(":")[2],
            location: message.split(":")[3],
            index: index,
            alert: message.split(":")[4] == "Emergency" ? true : false,
            icon: global.reasonIcons[index],
          ),
        ),
      );
    }
  }

  void onDisconnected() {
    log('MQTT Disconnected by Client');
    if (global.client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      log('MQTT Disconnection is correct');
    } else {
      log('MQTT Disconnection is incorrect');
    }
  }

  void onConnected() {
    log('MQTT Connection Successful');
  }

  void cancelCall() {
    global.payloadBuilder.clear();
    global.payloadBuilder.addString("CANCEL:" + global.personName);
    global.client.publishMessage(
        global.mqttTopic, MqttQos.exactlyOnce, global.payloadBuilder.payload!);
    global.callCancelled = false;
  }

  void setReason(int index, bool alert, Icon icon) async {
    Position currentPos = await determinePosition();
    global.currentLoc = currentPos;
    global.receiverName = "";
    global.receiverPhone = "";
    global.payloadBuilder.clear();
    global.payloadBuilder.addString("HELP:" +
        global.personName +
        ":" +
        global.phoneNumber +
        ":" +
        global.currentLoc.latitude.toString() +
        "," +
        global.currentLoc.longitude.toString() +
        ":" +
        global.reasons[index]);
    if (global.client.connectionState == MqttConnectionState.disconnected) {
      await connectMQTT();
    } else if (global.client.connectionState == MqttConnectionState.connected) {
      global.client.publishMessage(global.mqttTopic, MqttQos.exactlyOnce,
          global.payloadBuilder.payload!);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallSentScreen(
          index: index,
          alert: alert,
        ),
      ),
    );
  }

  Widget reasonCard(int index, bool alert, Icon icon) {
    return Hero(
      tag: 'reasonButton' + index.toString(),
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ElevatedButton(
            onPressed: () => setReason(index, alert, icon),
            child: Row(
              children: [
                icon,
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      global.reasons[index],
                      style: TextStyle(
                          color: alert ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              primary: alert ? Colors.red : Colors.grey[200],
            ),
          ),
        ),
      ),
    );
  }

  void aboutDialog() {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Avana 1.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Made for HackerEarth',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "By Yuvjeeth HS\nPushpalatha M",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void signOutDialog() {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: const Text(
                      'Are you sure you want to sign out?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  ButtonBar(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("No"),
                      ),
                      TextButton(
                        onPressed: () => deleteUserData(),
                        child: const Text("Yes"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  void deleteUserData() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/personalDetails.txt');
    file.deleteSync();
    global.personName = global.personAge = global.phoneNumber = "";
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PersonalDetailsScreen()),
    );
  }

  void handleClick(String selected) {
    if (selected == "Sign out") {
      signOutDialog();
    } else if (selected == "About") {
      aboutDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return {'Sign out', 'About'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'assistButton',
                    child: ElevatedButton(
                      onPressed: () => setReason(
                          global.reasons.indexOf("General"),
                          false,
                          global
                              .reasonIcons[global.reasons.indexOf("General")]),
                      child: const Text(
                        "Call for Help",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(250, 250),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              "Or is there anything specific you need help for?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: global.reasons.length,
                itemBuilder: (BuildContext context, int index) {
                  return reasonCard(
                    index,
                    index == 0 ? true : false,
                    global.reasonIcons[index],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
