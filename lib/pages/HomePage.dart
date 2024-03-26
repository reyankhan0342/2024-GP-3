import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool clicked = false;
  bool on1 = false;
  bool on2 = false;

  late TimeOfDay _selectedTime; // New variable to hold selected time

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "electech",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 2, 129, 55),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 250,
                  width: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(255, 2, 129, 55),
                      width: 4,
                    ),
                  ),
                  child: Text(
                    _selectedTime != null
                        ? _selectedTime.format(context)
                        : "Select Time",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetTimePage(
                            onSetTime: (selectedTime) {
                              setState(() {
                                _selectedTime = selectedTime;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text("Set Timer"),
                    color: Color.fromARGB(255, 45, 183, 77),
                    minSize: 50,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  const SizedBox(width: 15),
                  CupertinoButton(
                    onPressed: () {
                      clicked = true;
                      on1 = true;
                      startTimer();
                      clicked ? sendRequest("1", "ON") : {};
                      clicked ? sendRequest("2", "ON") : {};
                    },
                    child: const Text("ON"),
                    color: Color.fromARGB(255, 45, 183, 77),
                    minSize: 50,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  const SizedBox(width: 15),
                  CupertinoButton(
                    onPressed: () {
                      clicked = true;
                      on1 = false;
                      stopAndResetTimer();
                      clicked ? sendRequest("1", "OFF") : {};
                      clicked ? sendRequest("2", "OFF") : {};
                    },
                    child: const Text("OFF"),
                    color: Color.fromARGB(255, 45, 183, 77),
                    minSize: 50,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startTimer() {
    // Implement your timer logic here
  }

  void stopAndResetTimer() {
    // Implement your timer logic here
  }

  String sendingRequest(String relay, String status) {
    String completeLink = 'http://192.168.254.137/cm?cmnd=Power$relay $status';
    return completeLink;
  }

  sendRequest(String relay, String status) async {
    String link = sendingRequest(relay, status);
    final url = Uri.parse(link);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      print("Success");
    } else {
      print("Error");
    }
  }
}

class SetTimePage extends StatelessWidget {
  final Function(TimeOfDay)? onSetTime;

  const SetTimePage({Key? key, this.onSetTime}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Time"),
      ),
      body: Center(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: DateTime.now(),
          onDateTimeChanged: (selectedTime) {
            onSetTime?.call(TimeOfDay.fromDateTime(selectedTime));
          },
        ),
      ),
    );
  }
}
