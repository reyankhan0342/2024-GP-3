import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'SetTimePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stopwatch stopwatch;
  late Timer t;
  bool clicked = false;
  bool on1 = false;
  bool on2 = false;
  bool on3 = false;
  late DateTime _scheduledTime;
  bool _waterHeaterOn = false;

  @override
  void initializeState() {
    super.initState();
    stopwatch = Stopwatch();
    t = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    _scheduledTime = DateTime.now();
    // Load scheduled time from Firestore
    loadScheduledTime();
  }

  String returnFormattedText2() {
    var milli = stopwatch.elapsedMilliseconds;
    String milliseconds = (milli % 1000)
        .toString()
        .padLeft(2, "0"); // 1001 % 1000 = 1, 1450 % 1000 = 450
    String seconds = ((milli ~/ 1000) % 60).toString().padLeft(2, "0");
    String minutes = ((milli ~/ 1000) ~/ 60).toString().padLeft(2, "0");
    String hours =
        ((milli ~/ (1000 * 60 * 60)) % 24).toString().padLeft(2, "0");
    return "$hours:$minutes:$seconds";
  }

  void _toggleWaterHeater() {
    setState(() {
      _waterHeaterOn = !_waterHeaterOn;
      sendRequest(_waterHeaterOn ? "1" : "2", _waterHeaterOn ? "ON" : "OFF");
    });
  }

  void _scheduleAction(BuildContext context) async {
    final selectedTime = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetTimePage(onTimeSelected: (time) {
          setState(() {
            _scheduledTime = time;
          });
          // Save scheduled time to Firestore
          saveScheduledTime(time);
        }),
      ),
    );
    if (selectedTime != null) {
      setState(() {
        _scheduledTime = selectedTime;
      });
    }
  }

  void saveScheduledTime(DateTime scheduledTime) async {
    try {
      await FirebaseFirestore.instance
          .collection('ScheduledTimes')
          .doc(
              'user_id') // Replace 'user_id' with the actual user ID or a unique identifier
          .set({'scheduled_time': scheduledTime});
      print('Scheduled time saved successfully');
    } catch (e) {
      print('Error saving scheduled time: $e');
    }
  }

  void loadScheduledTime() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('ScheduledTimes')
          .doc(
              'user_id') // Replace 'user_id' with the actual user ID or a unique identifier
          .get();
      if (documentSnapshot.exists) {
        setState(() {
          _scheduledTime = (documentSnapshot.data()
                  as Map<String, dynamic>)['scheduled_time']
              .toDate();
        });
      }
    } catch (e) {
      print('Error loading scheduled time: $e');
    }
  }

  void startTimer() {
    stopwatch.start();
    savingFcmToken();
  }

  Future<void> savingFcmToken() async {
    String token = (await FirebaseMessaging.instance.getToken())!;
    await storeToken(token);
  }

  final _firebaseInstance = FirebaseFirestore.instance.collection(
      'FcmTokens'); // Replace 'FcmTokens' with your desired collection name

  Future<void> storeToken(String token) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseInstance
          .where('fcmT', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Token already exists in Firestore
        print('Token already exists');
      } else {
        // Token doesn't exist, save it with timestamp
        String randomId = _firebaseInstance.doc().id;
        DateTime now = DateTime.now();

        // Add 3 hours to the current time
        DateTime expirationTime = now.add(const Duration(minutes: 1));

        // Format the timestamp
        String formattedTime = DateFormat('h:mm a').format(expirationTime);
        // Format the date
        String formattedDate = DateFormat('d/M/yyyy').format(expirationTime);

        await _firebaseInstance.doc(randomId).set({
          'fcmT': token,
          'timestamp': formattedTime, // Store formatted time
          'date': formattedDate, // Store formatted date
        });
        print('Token stored successfully');
      }
    } catch (e) {
      print('Error storing token: $e');
    }
  }

  void stopTimer() {
    stopwatch.stop();
  }

  void resetTimer() {
    stopwatch.reset();
  }

  void stopAndResetTimer() async {
    stopTimer();
    await deleteToken();

    resetTimer();
  }

  Future<void> deleteToken() async {
    String token = (await FirebaseMessaging.instance.getToken())!;
    try {
      QuerySnapshot querySnapshot = await _firebaseInstance
          .where('fcmT', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Token exists in Firestore, delete it
        String documentId = querySnapshot.docs.first.id;
        await _firebaseInstance.doc(documentId).delete();
        print('Token deleted successfully');
      } else {
        // Token not found in Firestore
        print('Token not found');
      }
    } catch (e) {
      print('Error deleting token: $e');
    }
  }

  String returnFormattedText() {
    var milli = stopwatch.elapsed.inMilliseconds;
    String milliseconds = (milli % 1000)
        .toString()
        .padLeft(2, "0"); // 1001 % 1000 = 1, 1450 % 1000 = 450
    String seconds = ((milli ~/ 1000) % 60).toString().padLeft(2, "0");
    String minutes = ((milli ~/ 1000) ~/ 60).toString().padLeft(2, "0");
    String hours =
        ((milli ~/ (1000 * 60 * 60)) % 24).toString().padLeft(2, "0");
    return "$hours:$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    t = Timer.periodic(const Duration(microseconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

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
                    returnFormattedText(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 40,
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
                      clicked = true;
                      on1 = true;
                      startTimer();
                      clicked ? sendRequest("1", "ON") : {};
                      clicked ? sendRequest("2", "ON") : {};
                    },
                    color: const Color.fromARGB(255, 45, 183, 77),
                    minSize: 50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Text("ON"),
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
                    color: const Color.fromARGB(255, 45, 183, 77),
                    minSize: 50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Text("OFF"),
                  ),
                ],
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _scheduleAction(context),
                child: Text("Schedule Action"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String sendingRequset(String relay, String status) {
    String completeLink = 'http://192.168.254.169/cm?cmnd=Power$relay $status';
    return completeLink;
  }

  sendRequest(String relay, String status) async {
    try {
      String link = sendingRequset(relay, status);
      final url = Uri.parse(link);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print("Success");
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
