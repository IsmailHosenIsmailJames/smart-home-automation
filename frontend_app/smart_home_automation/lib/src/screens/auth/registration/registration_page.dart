import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:smart_home_automation/src/screens/auth/login/login_page.dart';
import 'package:smart_home_automation/src/screens/home/home_page.dart';
import 'package:toastification/toastification.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumber = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            SafeArea(
              child: Center(
                child: Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Gap(30),
            Text(
              "Name",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gap(5),
            TextFormField(
              controller: nameController,
              validator: (value) {
                if (value?.trim().isNotEmpty == true) {
                  return null;
                } else {
                  return "Name can't be empty";
                }
              },
              keyboardType: TextInputType.name,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(hintText: "Enter your name here..."),
            ),
            Gap(10),
            Text(
              "Email",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gap(5),
            TextFormField(
              controller: phoneNumber,
              validator: (value) {
                if (EmailValidator.validate(value ?? "")) {
                  return null;
                } else {
                  return "Email is not valid";
                }
              },
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(hintText: "Enter your email here..."),
            ),
            Gap(10),
            Text(
              "Password",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gap(5),
            TextFormField(
              validator: (value) {
                if (value?.trim().isNotEmpty == true && value!.length > 7) {
                  return null;
                } else {
                  return "password should be at least 8 char long";
                }
              },
              obscureText: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: password,
              keyboardType: TextInputType.visiblePassword,
              decoration:
                  InputDecoration(hintText: "Enter your password here..."),
            ),
            Gap(10),
            Text(
              "Confirm Password",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gap(5),
            TextFormField(
              validator: (value) {
                if (password.text == confirmPassword.text) {
                  return null;
                } else {
                  return "password should be at least 8 char long";
                }
              },
              obscureText: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: confirmPassword,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                  hintText: "Enter your password here again..."),
            ),
            Gap(20),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    if (formKey.currentState?.validate() == true) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => const CupertinoAlertDialog(
                          title: Text("Logging in..."),
                        ),
                      );
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                        email: phoneNumber.text,
                        password: password.text,
                      );
                      User? user = userCredential.user;
                      userCredential.user!
                          .updateDisplayName(nameController.text.trim());
                      if (user != null) {
                        String uid = user.uid;
                        await user
                            .updateDisplayName(nameController.text.trim());
                        await FirebaseFirestore.instance
                            .collection("user")
                            .doc(uid)
                            .set({
                          "name": nameController.text.trim(),
                          "phone": phoneNumber.text,
                          "password": password.text,
                        });
                        await FirebaseDatabase.instance.ref(uid).set({
                          "app": "",
                          "controller": "",
                        });
                        await Hive.box('info').put("userInfo", {
                          "name": nameController.text.trim(),
                          "phone": phoneNumber.text,
                          "password": password.text,
                          "uid": uid,
                        });
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                        Get.off(() => HomePage());
                      }
                    }
                  } catch (e) {
                    toastification.show(
                      // ignore: use_build_context_synchronously
                      context: context,
                      title: Text("Something went wrong"),
                      description: Text(e.toString()),
                      type: ToastificationType.error,
                      alignment: Alignment.bottomRight,
                      autoCloseDuration: Duration(seconds: 2),
                    );
                    log("Error with : \n$e");
                  }
                },
                child: Text("Register"),
              ),
            ),
            Gap(30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already registered? "),
                TextButton(
                  onPressed: () {
                    Get.off(() => LoginPage());
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
