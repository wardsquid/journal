// FireBase
import 'package:firebase_auth/firebase_auth.dart';
import 'managers/Firebase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Flutter Material
import 'package:flutter/material.dart';

// Pages
import 'views/LoginPage.dart';
import 'managers/pageView.dart';
import 'managers/userInfo.dart' as inkling;
import 'managers/Spotify.dart';

// For Spotify client key
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await setUpNotifications();
  await inkling.initializeUserCaching();
  await DotEnv().load('.env');
  await getSpotifyAuth();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
      debugShowCheckedModeBanner: false,
      home: _user == null ? LoginPage() : MainView(),
    );
  }
}
