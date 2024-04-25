import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationServces {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      provisional: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      sound: true,
    );

    if ((settings.authorizationStatus == AuthorizationStatus.authorized)) {
      print('user permission granded ');
    } else if (settings.criticalAlert == AuthorizationStatus.authorized) {
      print('user  granded provisional ');
    } else {
      print('user denaid permission ');
    }
  }
}
