import 'package:flutter/material.dart';
import 'package:humanitarian_icons/humanitarian_icons.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'global.dart' as global;

class CallReceiveScreen extends StatefulWidget {
  const CallReceiveScreen(
      {Key? key,
      this.personName,
      this.phoneNumber,
      this.location,
      this.index,
      this.alert,
      this.icon})
      : super(key: key);

  final personName;
  final phoneNumber;
  final location;
  final index;
  final alert;
  final icon;

  @override
  State<CallReceiveScreen> createState() => _CallReceiveScreen();
}

class _CallReceiveScreen extends State<CallReceiveScreen> {
  void empty() {}

  void launchPhone(String number) async {
    FlutterRingtonePlayer.stop();
    String url = "tel:" + number;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer.play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true, // Android only - API >= 28
      volume: 0.1, // Android only - API >= 28
      asAlarm: false, // Android only - all APIs
    );
    global.receivingCall = true;
  }

  @override
  void dispose() {
    super.dispose();
    FlutterRingtonePlayer.stop();
    global.receivingCall = false;
    global.callerName = "";
  }

  void startNavigation() {
    FlutterRingtonePlayer.stop();
    global.receivingCall = false;
    MapsLauncher.launchCoordinates(
        double.tryParse(widget.location.split(',')[0])!,
        double.tryParse(widget.location.split(',')[1])!);
    global.payloadBuilder.clear();
    global.payloadBuilder.addString("ACK:" +
        global.personName +
        ":" +
        global.phoneNumber +
        ":" +
        widget.personName);
    global.client.publishMessage(
        global.mqttTopic, MqttQos.exactlyOnce, global.payloadBuilder.payload!);
    Navigator.pop(context);
  }

  void dismissCall() {
    FlutterRingtonePlayer.stop();
    global.receivingCall = false;
    Navigator.pop(context);
  }

  Widget reasonCard(int index, bool alert, Icon icon) {
    return Hero(
      tag: 'reasonButton' + index.toString(),
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ElevatedButton(
            onPressed: () => empty(),
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
                    const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
                    Text(
                      global.reasonDescription[index],
                      style: TextStyle(
                          color: alert ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.normal),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Hero(
              tag: "assistButton",
              child: ElevatedButton(
                onPressed: empty,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.alert
                          ? "Incoming Emergency Help Request"
                          : "Incoming Help Request",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12)),
                    Text(
                      widget.personName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12)),
                    TextButton(
                      onPressed: widget.phoneNumber != ""
                          ? () => launchPhone(widget.phoneNumber)
                          : null,
                      child: Text(
                        widget.phoneNumber,
                        style:
                            const TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ),
                    widget.phoneNumber != ""
                        ? const Text("Tap the number to call")
                        : const Text(""),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.5),
                  primary: widget.alert ? Colors.red : Colors.green,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: reasonCard(widget.index, widget.alert, widget.icon),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
            SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width - 20,
              child: ElevatedButton(
                onPressed: startNavigation,
                child: const Text("Acknowledge and Navigate to Location"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
            SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width - 20,
              child: ElevatedButton(
                onPressed: dismissCall,
                child: const Text("Dismiss"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
