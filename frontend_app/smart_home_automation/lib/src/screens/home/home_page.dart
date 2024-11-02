import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:smart_home_automation/src/theme/colors.dart';
import 'package:toastification/toastification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          StreamBuilder(
            stream:
                FirebaseDatabase.instance.ref().child('/last_active').onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                String time = snapshot.data!.snapshot.value.toString();
                final timeDataList = time.split("-");
                int hour = (int.parse(timeDataList[3]) + 5) % 24;
                int minute = int.parse(timeDataList[4]);
                int second = int.parse(timeDataList[5]);
                return StreamBuilder(
                  stream: Stream.periodic(Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final now = DateTime.now();
                    final lastUpdateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      hour,
                      minute,
                      second,
                    );
                    final difference =
                        now.difference(lastUpdateTime).inSeconds.abs();
                    log("Signal got $difference seconds earlier");
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: difference > 30 ? Colors.red : Colors.green,
                      ),
                      padding: EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 2,
                        bottom: 2,
                      ),
                      margin: EdgeInsets.only(
                        right: 10,
                      ),
                      child: Text(
                        difference > 30 ? "Offline" : "Active",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                );
              } else {
                if (snapshot.hasError) {
                  return Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                  );
                }
                return Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.green.shade100,
                ),
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance.ref().child('/app').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!.snapshot.value!;
                      List<String> dataList = List<String>.from(
                        jsonDecode(
                          jsonEncode(data),
                        ),
                      );
                      return ListView.builder(
                        itemCount: dataList.length,
                        itemBuilder: (context, index) {
                          List<String> infoList = dataList[index].split(":");
                          return Row(
                            children: [Text(infoList[2])],
                          );
                        },
                      );
                    } else {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Something went wrong"),
                        );
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref()
                    .child('/controller')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!.snapshot.value.toString());
                  } else {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Something went wrong"),
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
