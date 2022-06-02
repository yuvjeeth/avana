import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:humanitarian_icons/humanitarian_icons.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'global.dart' as global;

class CallSentScreen extends StatefulWidget {
  const CallSentScreen({Key? key, required this.index, required this.alert})
      : super(key: key);

  final index;
  final alert;

  @override
  State<CallSentScreen> createState() => _CallSentScreen();
}

class _CallSentScreen extends State<CallSentScreen> {
  late Timer refresh;
  void empty() {}

  @override
  void initState() {
    super.initState();
    global.receiverName = "";
    global.receiverPhone = "";
    refresh = Timer.periodic(const Duration(seconds: 5), (timer) {
      log("Refresh State");

      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    refresh.cancel();
    global.callCancelled = true;
  }

  void launchPhone(String number) async {
    String url = "tel:" + number;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Hero(
            tag: "assistButton",
            child: ElevatedButton(
              onPressed: empty,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Reaching out for help...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12)),
                  Text(
                    "Your request for help has been broadcasted, we'll get back to you when your request is accepted.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: reasonCard(
                widget.index, widget.alert, global.reasonIcons[widget.index]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
          ),
          const Text(
            "Your request has been accepted by:",
            style: TextStyle(fontSize: 16),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
          ),
          global.receiverName == ""
              ? const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: null,
                  ))
              : Text(
                  global.receiverName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
          ),
          TextButton(
            onPressed: global.receiverPhone != ""
                ? () => launchPhone(global.receiverPhone)
                : null,
            child: Text(
              global.receiverPhone,
              style: const TextStyle(
                fontSize: 30,
              ),
            ),
          ),
          global.receiverPhone != ""
              ? const Text("Tap the number to call")
              : const Text(""),
        ],
      ),
    );
  }
}
