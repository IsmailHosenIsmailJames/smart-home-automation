import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:smart_home_automation/src/theme/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset("assets/logo.png"),
                ),
                Gap(30),
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 40,
                    color: AppColors().primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(30),
                Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 10),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: TextFormField(
                    validator: (value) {
                      if (EmailValidator.validate(email.text) == false) {
                        return "Please enter a valid email";
                      } else {
                        return null;
                      }
                    },
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        border: InputBorder.none, hintText: "Email"),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  margin: const EdgeInsets.only(
                    top: 5,
                    bottom: 10,
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  child: TextFormField(
                    validator: (value) {
                      if ((value?.length ?? 0) < 6) {
                        return "Password must be at least 6 characters";
                      } else {
                        return null;
                      }
                    },
                    keyboardType: TextInputType.visiblePassword,
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Password",
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => const CupertinoAlertDialog(
                            title: Text("Logging in..."),
                          ),
                        );
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: email.text,
                          password: password.text,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
