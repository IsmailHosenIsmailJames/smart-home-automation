import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:smart_home_automation/src/screens/get_microcontroller_code/code_to_copy.dart';

class GetMicrocontrollerCode extends StatefulWidget {
  const GetMicrocontrollerCode({super.key});

  @override
  State<GetMicrocontrollerCode> createState() => _GetMicrocontrollerCodeState();
}

class _GetMicrocontrollerCodeState extends State<GetMicrocontrollerCode> {
  TextEditingController wifiSSIDController = TextEditingController();
  TextEditingController wifiSSIDPassword = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Get Code"),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.all(10),
          children: [
            Center(
              child: Text(
                "Please provide required info for controller",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            Gap(20),
            Text(
              "WiFi SSID for controller",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(5),
            TextFormField(
              controller: wifiSSIDController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Not valid";
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration:
                  InputDecoration(hintText: "Type WiFi SSID for controller..."),
            ),
            Gap(20),
            Text(
              "WiFi SSID for controller",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(5),
            TextFormField(
              controller: wifiSSIDPassword,
              validator: (value) {
                if (value == null || value.length < 8) {
                  return "Not valid";
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration:
                  InputDecoration(hintText: "Type WiFi SSID for controller..."),
            ),
            Gap(20),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  final String code =
                      await rootBundle.loadString('assets/code/main.cpp');
                  Get.to(
                    () => CodeToCopy(
                      wifiSsid: wifiSSIDController.text.trim(),
                      wifiPassword: wifiSSIDPassword.text,
                      code: code,
                    ),
                  );
                }
              },
              child: Text("Get Code"),
            ),
          ],
        ),
      ),
    );
  }
}
