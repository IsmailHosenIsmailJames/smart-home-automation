import 'package:firebase_database/firebase_database.dart';
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
      body: Center(
        child: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref().child('/elements').onValue,
          builder:
              (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              Map<String, dynamic> data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);
              List<ModeOfElements> elements = [];
              List<String> elementsNames = [];
              data.forEach(
                (key, value) {
                 if(key!= "names"){ elementsNames.add(key);}
                if(key!= "names") {   elements.add(
                    ModeOfElements.fromMap(Map<String, dynamic>.from(value)),
                  );}
                },
              );
              return SingleChildScrollView(
                child: Column(
                  children: List<Widget>.generate(
                        elementsNames.length,
                        (index) {
                          return Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  elementsNames[index],
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Spacer(),
                                if (elements[index].feedback != "done" &&
                                    (elements[index].state !=
                                        elements[index].request))
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      IconButton(
                                        onPressed: () async {
                                          toastification.show(
                                            context: context,
                                            type: ToastificationType.warning,
                                            title: Text(
                                                'The request has been Canceled'),
                                            autoCloseDuration:
                                                const Duration(seconds: 2),
                                          );
                                          await FirebaseDatabase.instance
                                              .ref(
                                                  "/elements/${elementsNames[index]}/request")
                                              .set(elements[index].state);
                                          await FirebaseDatabase.instance
                                              .ref(
                                                  "/elements/${elementsNames[index]}/feedback")
                                              .set("done");
                                        },
                                        icon: Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                Gap(10),
                                SizedBox(
                                  child: Switch(
                                    value: elements[index].state,
                                    onChanged: (value) async {
                                      if (!(elements[index].feedback !=
                                              "Done" &&
                                          (elements[index].state !=
                                              elements[index].request))) {
                                        toastification.show(
                                          context: context,
                                          type: ToastificationType.info,
                                          title: Text(
                                              'Send a request to change the state of ${elementsNames[index]}'),
                                          autoCloseDuration:
                                              const Duration(seconds: 2),
                                        );
                                      } else {
                                        toastification.show(
                                          context: context,
                                          type: ToastificationType.info,
                                          title: Text(
                                              'The request has already been sent'),
                                          autoCloseDuration:
                                              const Duration(seconds: 2),
                                        );
                                      }
                                      await Future.delayed(
                                          Duration(milliseconds: 300));
                                      await FirebaseDatabase.instance
                                          .ref(
                                              "/elements/${elementsNames[index]}/request")
                                          .set(!elements[index].state);
                                      await FirebaseDatabase.instance
                                          .ref(
                                              "/elements/${elementsNames[index]}/feedback")
                                          .set("Pending");
                                    },
                                  ),
                                ),
                                Gap(5),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.edit,
                                    color: AppColors().primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ) +
                      <Widget>[
                        Container(
                          margin: EdgeInsets.all(10),
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {},
                            icon: Icon(Icons.add),
                            label: Text("Add New Element"),
                          ),
                        ),
                      ],
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
