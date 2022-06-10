import 'dart:io';

import 'package:flutter/material.dart';
import 'package:avana/initiate_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'global.dart' as global;

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreen();
}

class _PersonalDetailsScreen extends State<PersonalDetailsScreen> {
  TextEditingController txtName = TextEditingController();
  TextEditingController txtAge = TextEditingController();
  TextEditingController txtPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    readPersonalDetails();
  }

  void empty() {}

  void savePersonalDetails() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/personalDetails.txt');
    String writeText =
        txtName.text + "," + txtAge.text + "," + txtPhone.text + ",";
    global.isSpeciallyAbled
        ? writeText = writeText + "1,"
        : writeText = writeText + "0,";
    global.isHelpNeeded
        ? writeText = writeText + "1,"
        : writeText = writeText + "0,";
    global.isVolunteering
        ? writeText = writeText + "1"
        : writeText = writeText + "0";
    file.writeAsStringSync(writeText, mode: FileMode.writeOnly);
  }

  void readPersonalDetails() async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/personalDetails.txt');
      String details = file.readAsStringSync();
      global.personName = details.split(",")[0];
      global.personAge = details.split(",")[1];
      global.phoneNumber = details.split(",")[2];
      global.isSpeciallyAbled = details.split(",")[3] == "1" ? true : false;
      global.isHelpNeeded = details.split(",")[4] == "1" ? true : false;
      global.isVolunteering = details.split(",")[5] == "1" ? true : false;

      if (global.personName != "" && global.personAge != "") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const InitiateScreen(title: "Avana"),
          ),
        );
      }
    } catch (e) {}
  }

  void signUp() {
    if (txtName.text.isNotEmpty && txtName.text.length >= 3) {
      var age = int.tryParse(txtAge.text);
      age == null ? age = 0 : age = age;
      if (age > 12 && age < 100) {
        if (txtPhone.text.isNotEmpty) {
          global.personName = txtName.text;
          global.personAge = txtAge.text;
          global.phoneNumber = txtPhone.text;
          savePersonalDetails();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const InitiateScreen(title: "Avana"),
            ),
          );
        } else {
          Fluttertoast.showToast(
              msg: "Please enter a valid 10-digit phone number");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Please enter a valid age between 12 and 100.");
      }
    } else {
      Fluttertoast.showToast(msg: "Please enter a valid name.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text("Avana"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Your Details",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                SizedBox(
                  height: 80,
                  width: MediaQuery.of(context).size.width,
                  child: TextFormField(
                    controller: txtName,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        labelText: "Name",
                        hintText: "What can we call you?"),
                  ),
                ),
                SizedBox(
                  height: 80,
                  width: MediaQuery.of(context).size.width,
                  child: TextFormField(
                    controller: txtAge,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.align_vertical_bottom_rounded),
                        labelText: "Age",
                        hintText: "How young are you?"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  height: 80,
                  width: MediaQuery.of(context).size.width,
                  child: TextFormField(
                    controller: txtPhone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.phone),
                        labelText: "Phone number",
                        hintText: "+91"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Are you specially abled? ",
                      style: TextStyle(fontSize: 16),
                    ),
                    Checkbox(
                        value: global.isSpeciallyAbled,
                        onChanged: (bool? value) {
                          setState(() {
                            global.isSpeciallyAbled = value!;
                          });
                        }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Do you feel you need someone to\nsupport you while outdoors?",
                      style: TextStyle(fontSize: 16),
                    ),
                    Checkbox(
                        value: global.isHelpNeeded,
                        onChanged: (bool? value) {
                          setState(() {
                            global.isHelpNeeded = value!;
                          });
                        }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Would you volunteer to help others\nwhen they're in need?",
                      style: TextStyle(fontSize: 16),
                    ),
                    Checkbox(
                        value: global.isVolunteering,
                        onChanged: (bool? value) {
                          setState(() {
                            global.isVolunteering = value!;
                          });
                        }),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                Hero(
                  tag: 'assistButton',
                  child: ElevatedButton(
                    onPressed: () => signUp(),
                    child: const Text(
                      "Sign Up",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width, 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
