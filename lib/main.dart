// FireBase
import 'package:firebase_auth/firebase_auth.dart';
import 'managers/Firebase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Flutter Material
import 'package:flutter/material.dart';

// Pages
import 'views/LoginPage.dart';
import 'managers/pageView.dart';

// Spotify
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:spotify_sdk/models/crossfade_state.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/models/player_context.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await setUpNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await DotEnv().load('.env');
  print(DotEnv().env['CLIENT_ID']);
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
