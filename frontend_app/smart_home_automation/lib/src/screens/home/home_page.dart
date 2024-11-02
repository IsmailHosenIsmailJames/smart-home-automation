import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
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
                      return appStateWidget(dataList);
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
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.blue.shade100,
                ),
                margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                padding: EdgeInsets.all(20),
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref()
                      .child('/controller')
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!.snapshot.value!;
                      List<String> dataList = List<String>.from(
                        jsonDecode(
                          jsonEncode(data),
                        ),
                      );
                      return controllerStateWidget(dataList);
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
          ],
        ),
      ),
    );
  }

  Column controllerStateWidget(List<String> dataList) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "ESP32-S3 State",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.black,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              List<String> infoList = dataList[index].split(":");
              if (infoList.length != 3) return Container();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(
                      left: 10,
                      top: 3,
                      bottom: 3,
                      right: 10,
                    ),
                    margin: EdgeInsets.only(
                      top: 3,
                      bottom: 3,
                    ),
                    child: Text(infoList[2]),
                  ),
                  Container(
                    color: Colors.blue.shade700,
                    width: MediaQuery.of(context).size.width * 0.05,
                    height: 1,
                  ),
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(
                      left: 10,
                      top: 3,
                      bottom: 3,
                      right: 10,
                    ),
                    margin: EdgeInsets.only(
                      top: 3,
                      bottom: 3,
                    ),
                    child: Text("Pin: ${infoList[0]}"),
                  ),
                  Container(
                    color: Colors.blue.shade700,
                    width: MediaQuery.of(context).size.width * 0.05,
                    height: 1,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    height: 40,
                    margin: EdgeInsets.only(top: 5, bottom: 5),
                    child: Switch.adaptive(
                      value: infoList[1] == "1",
                      onChanged: (value) {},
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Column appStateWidget(List<String> dataList) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "App State",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            Spacer(),
            SizedBox(
              height: 30,
              width: 50,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                iconSize: 18,
                padding: EdgeInsets.zero,
                color: Colors.red.shade400,
                icon: Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return onDeleteElements(dataList);
                      });
                },
              ),
            ),
            Gap(10),
            SizedBox(
              height: 30,
              width: 50,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                iconSize: 18,
                padding: EdgeInsets.zero,
                color: Colors.green.shade700,
                onPressed: () {
                  TextEditingController pinController = TextEditingController();
                  TextEditingController nameController =
                      TextEditingController();

                  final formKey = GlobalKey<FormState>();
                  showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          insetPadding: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Form(
                            key: formKey,
                            child: Container(
                              height: 300,
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(
                                    "Add new element",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Divider(color: Colors.black),
                                  Gap(15),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.only(left: 10),
                                    child: TextFormField(
                                      controller: pinController,
                                      validator: (value) {
                                        if (int.tryParse(value ?? "") == null) {
                                          return "Enter valid pin number";
                                        } else {
                                          return null;
                                        }
                                      },
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "type Pin number here",
                                      ),
                                    ),
                                  ),
                                  Gap(10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.only(left: 10),
                                    child: TextFormField(
                                      controller: nameController,
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty ||
                                            value.length > 20) {
                                          return "Enter element name between 1 to 20 characters";
                                        } else {
                                          return null;
                                        }
                                      },
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "type element name here..",
                                      ),
                                    ),
                                  ),
                                  Gap(20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          FirebaseDatabase.instance
                                              .ref()
                                              .child("/app/${dataList.length}")
                                              .set(
                                                  "${pinController.text}:0:${nameController.text.trim()}")
                                              .then(
                                            (value) {
                                              Navigator.pop(context);
                                              toastification.show(
                                                context: context,
                                                title:
                                                    Text("Added successfully"),
                                                type:
                                                    ToastificationType.success,
                                              );
                                            },
                                          );
                                        }
                                      },
                                      icon: Icon(Icons.add),
                                      label: Text(
                                        "Add",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                },
                icon: Icon(Icons.add),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.black,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              List<String> infoList = dataList[index].split(":");
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(
                      left: 10,
                      top: 3,
                      bottom: 3,
                      right: 10,
                    ),
                    margin: EdgeInsets.only(
                      top: 3,
                      bottom: 3,
                    ),
                    child: FittedBox(
                      child: Text(
                        infoList[2],
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.blue.shade700,
                    width: MediaQuery.of(context).size.width * 0.05,
                    height: 1,
                  ),
                  Container(
                    width: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(
                      left: 10,
                      top: 3,
                      bottom: 3,
                      right: 10,
                    ),
                    margin: EdgeInsets.only(
                      top: 3,
                      bottom: 3,
                    ),
                    child: Text("Pin: ${infoList[0]}"),
                  ),
                  Container(
                    color: Colors.blue.shade700,
                    width: MediaQuery.of(context).size.width * 0.05,
                    height: 1,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    height: 40,
                    margin: EdgeInsets.only(top: 5, bottom: 5),
                    child: Switch.adaptive(
                      value: infoList[1] == "1",
                      onChanged: (value) async {
                        await FirebaseDatabase.instance
                            .ref()
                            .child('/app/$index')
                            .set(
                              "${infoList[0]}:${value ? "1" : "0"}:${infoList[2]}",
                            )
                            .then((v) {
                          toastification.show(
                            context: context,
                            title: Text(
                                "${infoList[2]} is now ${value ? "ON" : "OFF"}"),
                            autoCloseDuration: const Duration(seconds: 2),
                          );
                        });
                      },
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Dialog onDeleteElements(List<String> dataList) {
    return Dialog(
      insetPadding: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        height: 300,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Which do you want to delete?",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            Divider(
              color: Colors.black,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  List<String> infoList = dataList[index].split(":");
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: 2,
                      top: 2,
                    ),
                    child: Row(
                      children: [
                        Text(infoList[2]),
                        Spacer(),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          color: Colors.red.shade400,
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            if (dataList.length <= 1) {
                              toastification.show(
                                title: Text("All can't be deleted!"),
                              );
                            }
                            FirebaseDatabase.instance
                                .ref()
                                .child('/app')
                                .child(index.toString())
                                .remove()
                                .then(
                              (value) {
                                Navigator.pop(context);
                                toastification.show(
                                  title: Text("Deleted from App!"),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
