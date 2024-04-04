import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stopwatch stopwatch;
  late Timer t;
  bool clicked = false;
  bool on1 = false;
  bool on2 = false;
  var time = DateTime.now();

  bool on3 = false;
  void startTimer() {
    stopwatch.start();
    savingFcmToken();
  }

  Future<void> savingFcmToken() async {
    String token = (await FirebaseMessaging.instance.getToken())!;
    await storeToken(token);
  }

  final _firebaseInstance = FirebaseFirestore.instance.collection('FcmTokens');

  Future<void> storeToken(String token) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseInstance
          .where('fcmT', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Token already exists');
      } else {
        String randomId = _firebaseInstance.doc().id;
        DateTime now = DateTime.now();
        DateTime expirationTime = now.add(const Duration(minutes: 2));
        String formattedTime = DateFormat('h:mm a').format(expirationTime);
        String formattedDate = DateFormat('d/M/yyyy').format(expirationTime);

        await _firebaseInstance.doc(randomId).set({
          'fcmT': token,
          'timestamp': formattedTime,
          'date': formattedDate,
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
        String documentId = querySnapshot.docs.first.id;
        await _firebaseInstance.doc(documentId).delete();
        print('Token deleted successfully');
      } else {
        print('Token not found');
      }
    } catch (e) {
      print('Error deleting token: $e');
    }
  }

  String returnFormattedText() {
    var milli = stopwatch.elapsed.inMilliseconds;
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

                      // Save the current date to Firestore with action 'ON'
                      saveDateToFirestore('ON');
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

                      // Save the current date to Firestore with action 'OFF'
                      saveDateToFirestore('OFF');
                    },
                    child: const Text("OFF"),
                    color: Color.fromARGB(255, 45, 183, 77),
                    minSize: 50,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ],
              ),
              SizedBox(height: 15),
              // DataTable
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('FcmTokens')
                    .orderBy('timestamp',
                        descending:
                            true) // Order by timestamp in descending order
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final fcmTokens = snapshot.data?.docs;

                  if (fcmTokens == null || fcmTokens.isEmpty) {
                    return Expanded(
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Timestamp')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: [], // Empty list of DataRow
                      ),
                    );
                  }

// Filter the documents to include only those with timestamp within the first hour
                  //final filteredTokens = fcmTokens.where((token) {
                  //final timestamp = token['timestamp'];
                  //if (timestamp != null && timestamp is String) {
                  //final time = DateFormat('h:mm a').parse(timestamp);
                  // Check if the timestamp is within the first hour
                  //return time.hour == DateTime.now().hour;
                  //}
                  //return false;
                  //}).toList();

                  final filteredTokens = fcmTokens.where((token) {
                    final date = token['date'];
                    if (date != null && date is String) {
                      final parts = date.split('/');
                      if (parts.length == 3) {
                        final month = int.tryParse(parts[1]);
                        // Check if the date is within the current month
                        return month == DateTime.now().month;
                      }
                    }
                    return false;
                  }).toList();

                  return Expanded(
                    child: SingleChildScrollView(
                      // Wrap DataTable with SingleChildScrollView
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Timestamp')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: filteredTokens.map((fcmToken) {
                          final date = fcmToken['date'] ?? '';
                          final timestamp = fcmToken['timestamp'] ?? '';
                          final action =
                              (fcmToken.data() as Map<String, dynamic>?)
                                          ?.containsKey('action') ??
                                      false
                                  ? fcmToken['action']
                                  : '';

                          return DataRow(cells: [
                            DataCell(Text(date)),
                            DataCell(Text(timestamp)),
                            DataCell(Text(
                                action)), // Use empty string if action is not available
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String sendingRequset(String relay, String status) {
    String completeLink = 'http://192.168.254.137/cm?cmnd=Power$relay $status';
    return completeLink;
  }

  sendRequest(String relay, String status) async {
    String link = sendingRequset(relay, status);
    final url = Uri.parse(link);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      print("Success");
    } else {
      print("error");
    }
  }

  Future<void> saveDateToFirestore(String action) async {
    try {
      DateTime now = DateTime.now();
      String formattedTime = DateFormat('h:mm a').format(now);
      String formattedDate = DateFormat('d/M/yyyy').format(now);

      await _firebaseInstance.add({
        'timestamp': formattedTime,
        'date': formattedDate,
        'action': action,
      });
      print('Date stored successfully');
    } catch (e) {
      print('Error storing date: $e');
    }
  }
}
