import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:smart_home_automation/src/screens/auth/login/login_page.dart';
import 'package:smart_home_automation/src/screens/get_microcontroller_code/get_microcontroller_code.dart';
import 'package:smart_home_automation/src/screens/home/controller/home_controller.dart';
import 'package:toastification/toastification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User user = FirebaseAuth.instance.currentUser!;
  int pushedIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    radius: 35,
                    child:
                        Text(("${user.displayName ?? "  "}  ").substring(0, 2)),
                  ),
                  Gap(10),
                  Text(user.displayName ?? ""),
                  SelectableText(
                    "UID: ${user.uid}",
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    "Dynamic Automation",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => GetMicrocontrollerCode());
                      },
                      child: Text("Get Code"),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        await Hive.box('info').clear();
                        Get.to(() => LoginPage());
                      },
                      child: Text("Log Out"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref(user.uid)
                .child('/last_active')
                .onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data == null) {
                  return unActiveWidget;
                }
                try {
                  String time = snapshot.data!.snapshot.value.toString();
                  final timeDataList = time.split("-");
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
                        now.hour,
                        minute,
                        second,
                      );
                      final difference =
                          now.difference(lastUpdateTime).inSeconds.abs();
                      log("Signal got $difference seconds earlier");
                      return difference > 30 ? unActiveWidget : activeWidget;
                    },
                  );
                } catch (e) {
                  return unActiveWidget;
                }
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
                  stream: FirebaseDatabase.instance
                      .ref(user.uid)
                      .child('/app')
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      try {
                        final data = snapshot.data!.snapshot.value!;
                        if (data.toString().isEmpty) {
                          return appStateWidget([]);
                        }

                        List<String> dataList = data.toString().split(',');

                        return appStateWidget(dataList);
                      } catch (e) {
                        return Center(
                          child: Text("Unable to process"),
                        );
                      }
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
                      .ref(user.uid)
                      .child('/controller')
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      try {
                        final data = snapshot.data!.snapshot.value!;
                        if (data.toString().isEmpty) {
                          return controllerStateWidget([]);
                        }
                        List<String> dataList = data.toString().split(',');

                        return controllerStateWidget(dataList);
                      } catch (e) {
                        return Center(
                          child: Text("Unable to process"),
                        );
                      }
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
        dataList.isEmpty
            ? Text("Empty")
            : Expanded(
                child: ListView.builder(
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    if (dataList[index].isEmpty) return SizedBox();
                    List<String> infoList = dataList[index].split(":");
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue.shade700,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                                left: 10, top: 3, bottom: 3, right: 10),
                            scrollDirection: Axis.horizontal,
                            child: FutureBuilder(
                              future: FirebaseDatabase.instance
                                  .ref(user.uid)
                                  .child("name")
                                  .child(infoList[0].toString())
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(snapshot.data?.value
                                          .toString()
                                          .split("?")[0] ??
                                      "");
                                }
                                return Text("...");
                              },
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
                            inactiveThumbColor: Colors.black,
                            onChanged: null,
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
                  onAddNewElement(
                    formKey,
                    pinController,
                    nameController,
                    dataList,
                  );
                },
                icon: Icon(Icons.add),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.black,
        ),
        dataList.isEmpty
            ? Text("Empty")
            : Expanded(
                child: ListView.builder(
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    if (dataList[index].contains(':') == false) {
                      return SizedBox();
                    }
                    List<String> infoList = dataList[index].split(":");

                    return FutureBuilder(
                        future: FirebaseDatabase.instance
                            .ref(user.uid)
                            .child("name")
                            .child(infoList[0].toString())
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text("...");
                          }
                          String pinName =
                              snapshot.data?.value.toString() ?? "";
                          bool isPushButton =
                              pinName.contains("?type=Push Button");

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
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.only(
                                      left: 10, top: 3, bottom: 3, right: 10),
                                  scrollDirection: Axis.horizontal,
                                  child: Text(snapshot.data?.value
                                          .toString()
                                          .split("?")[0] ??
                                      ""),
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
                                child: isPushButton
                                    ? GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        child: Container(
                                          height: 50,
                                          width: 60,
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: [
                                                if (index == pushedIndex)
                                                  BoxShadow(
                                                    spreadRadius: 10,
                                                    blurRadius: 10,
                                                    color: Colors.red,
                                                  ),
                                              ]),
                                          child: Center(
                                            child: Text(
                                              index == pushedIndex
                                                  ? "Pull"
                                                  : "Push",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        onTapDown: (TapDownDetails
                                            tapDownDetails) async {
                                          try {
                                            final controller =
                                                Get.put(HomeController());
                                            controller.previousSateOfSwitches
                                                .value = dataList;
                                            await onSwitchOn(
                                              dataList,
                                              index,
                                              infoList,
                                              context,
                                              state: true,
                                            );
                                            setState(() {
                                              pushedIndex = index;
                                            });
                                          } catch (e) {
                                            log(e.toString());
                                          }
                                        },
                                        onTapUp: (details) async {
                                          try {
                                            final controller =
                                                Get.put(HomeController());

                                            await onSwitchOn(
                                              controller.previousSateOfSwitches,
                                              index,
                                              infoList,
                                              context,
                                              state: false,
                                            );

                                            setState(() {
                                              pushedIndex = -1;
                                            });
                                          } catch (e) {
                                            log(e.toString());
                                          }
                                        },
                                      )
                                    : Switch.adaptive(
                                        value: infoList[1] == "1",
                                        onChanged: (value) async {
                                          try {
                                            await onSwitchOn(dataList, index,
                                                infoList, context);
                                          } catch (e) {
                                            toastification.show(
                                              context: context,
                                              title:
                                                  Text("Something went wrong"),
                                              autoCloseDuration:
                                                  const Duration(seconds: 2),
                                              type: ToastificationType.error,
                                              alignment: Alignment.bottomRight,
                                            );
                                          }
                                        },
                                      ),
                              )
                            ],
                          );
                        });
                  },
                ),
              ),
      ],
    );
  }

  Future<void> onSwitchOn(List<String> dataList, int index,
      List<String> infoList, BuildContext context,
      {bool? state}) async {
    String command = state != null
        ? state == true
            ? "1"
            : "0"
        : infoList[1] == '1'
            ? "0"
            : "1";
    dataList[index] = "${infoList[0]}:$command";
    String toSend = "";
    for (String info in dataList) {
      if (info.isNotEmpty) {
        toSend += "$info,";
      }
    }

    await FirebaseDatabase.instance
        .ref(user.uid)
        .child('app')
        .set(toSend)
        .then((v) {
      toastification.show(
        context: context,
        title: Text("Successful"),
        description: Text("Command have send to server."),
        autoCloseDuration: const Duration(seconds: 2),
        type: ToastificationType.success,
        alignment: Alignment.bottomRight,
      );
    });
  }

  void onAddNewElement(
    GlobalKey<FormState> formKey,
    TextEditingController pinController,
    TextEditingController nameController,
    List<String> dataList,
  ) {
    String buttonType = "Switch Button";
    List<String> buttonTypeList = ["Switch Button", "Push Button"];
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
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            for (String s in dataList) {
                              List<String> infoList = s.split(":");
                              if (infoList[0] == value) {
                                return "This pin is already in use";
                              }
                            }

                            return null;
                          }
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "type element name here..",
                        ),
                      ),
                    ),
                    Gap(10),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton(
                        isExpanded: true,
                        items: List.generate(
                          buttonTypeList.length,
                          (index) => DropdownMenuItem(
                            value: buttonTypeList[index],
                            child: Text(
                              buttonTypeList[index],
                            ),
                          ),
                        ),
                        value: buttonType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              buttonType = value;
                            });
                          }
                        },
                      ),
                    ),
                    Gap(20),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              String name = nameController.text.trim();
                              name += "?type=$buttonType";
                              await FirebaseDatabase.instance
                                  .ref(user.uid)
                                  .child('name')
                                  .update({
                                pinController.text.trim(): name,
                              });
                              final data = await FirebaseDatabase.instance
                                  .ref(user.uid)
                                  .child("app")
                                  .get();
                              String toSend = "";
                              if (data.exists) {
                                toSend += "${data.value}";
                              }
                              toSend += "${pinController.text.trim()}:0,";
                              await FirebaseDatabase.instance
                                  .ref(user.uid)
                                  .child('app')
                                  .set(toSend);

                              toastification.show(
                                context: context,
                                title: Text("Added"),
                                type: ToastificationType.success,
                                alignment: Alignment.bottomRight,
                                autoCloseDuration: Duration(seconds: 2),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              toastification.show(
                                context: context,
                                title: Text("Unsuccessful"),
                                description: Text(e.toString()),
                                type: ToastificationType.success,
                                alignment: Alignment.bottomRight,
                                autoCloseDuration: Duration(seconds: 2),
                              );
                            }
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
  }

  Dialog onDeleteElements(List<String> dataList) {
    print(dataList);
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
                  if (infoList.length == 1) return SizedBox();
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
                        FutureBuilder(
                          future: FirebaseDatabase.instance
                              .ref(user.uid)
                              .child("name")
                              .child(infoList[0].toString())
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                  snapshot.data?.value.toString() ?? "");
                            }
                            return Text("...");
                          },
                        ),
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
                            String toSend = "";
                            dataList.removeAt(index);
                            for (String data in dataList) {
                              if (data.isNotEmpty) {
                                toSend += "$data,";
                              }
                            }

                            FirebaseDatabase.instance
                                .ref(user.uid)
                                .child('/app')
                                .set(toSend)
                                .then(
                              (value) {
                                Navigator.pop(context);
                                toastification.show(
                                  context: context,
                                  title: Text("Deleted from App!"),
                                  alignment: Alignment.bottomRight,
                                  autoCloseDuration: Duration(seconds: 2),
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

  Widget activeWidget = Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.green,
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
      "Active",
      style: TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  Widget unActiveWidget = Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.red,
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
      "Offline",
      style: TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
