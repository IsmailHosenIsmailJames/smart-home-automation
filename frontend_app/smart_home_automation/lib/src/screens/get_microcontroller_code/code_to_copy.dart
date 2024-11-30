import 'package:clipboard/clipboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:hive/hive.dart';
import 'package:toastification/toastification.dart';

class CodeToCopy extends StatefulWidget {
  final String wifiSsid;
  final String wifiPassword;
  final String code;
  const CodeToCopy({
    super.key,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.code,
  });

  @override
  State<CodeToCopy> createState() => _CodeToCopyState();
}

class _CodeToCopyState extends State<CodeToCopy> {
  User user = FirebaseAuth.instance.currentUser!;

  late String uid;
  late String userEmail;
  late String userPassword;

  late CodeController controller;

  @override
  void initState() {
    uid = user.uid;
    userEmail = user.email!;
    userPassword = Hive.box('info').get('userInfo')['password'];
    controller = CodeController(
      text: widget.code
          .replaceAll("WIFI_SSID_NAME_PASTE_HERE", widget.wifiSsid)
          .replaceAll("WIFI_SSID_PASSWORD_PASTE_HERE", widget.wifiSsid)
          .replaceAll("USER_CREDHANTAIL_EMAIL", userEmail)
          .replaceAll("USER_CREDHANTAIL_PASSWORD", userPassword)
          .replaceAll("USER_UID_PASTE_HERE", uid),
      language: cpp,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Copy the code",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 30,
              width: 100,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FlutterClipboard.copy(controller.fullText);
                  toastification.show(
                    title: Text("Copied"),
                    context: context,
                    type: ToastificationType.success,
                    alignment: Alignment.bottomRight,
                    autoCloseDuration: Duration(seconds: 2),
                  );
                },
                icon: Icon(
                  Icons.copy,
                  size: 16,
                ),
                label: Text(
                  "Copy",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(0.8),
        ),
        child: CodeTheme(
          data: CodeThemeData(
            styles: monokaiSublimeTheme,
          ),
          child: SingleChildScrollView(
            child: CodeField(
              lineNumbers: false,
              textStyle: GoogleFonts.sourceCodePro(),
              controller: controller,
            ),
          ),
        ),
      ),
    );
  }
}
