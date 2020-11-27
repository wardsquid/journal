import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'Splash_Screen.dart';
import 'package:flutter/material.dart';
import 'views/LoginPage.dart';
import 'manager/Firebase.dart';
import 'Navigation.dart'; 

//For Flutter__Local_Notifications_plugin
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

//initializing the plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

//initialize settings for Flutter__Local_Notifications_plugin
  var initializationSettingsAndroid =
      AndroidInitializationSettings('defaultIcon');
  var initializationSettingsIOS = IOSInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: 
        (int id, String title, String body, String payload) async {});
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid, 
    iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  });
//--End--//

  await initializeFirebase();
  await setUpNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  final User _user = checkUserLoginStatus();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inkling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _user == null ? LoginPage() : Navigation(), //SplashScreen(),
    );
  }
}
