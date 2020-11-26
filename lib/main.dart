import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'Splash_Screen.dart';
import 'package:flutter/material.dart';
import 'views/LoginPage.dart';
import 'manager/Firebase.dart';
import 'Navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
