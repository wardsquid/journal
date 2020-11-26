import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseMessaging _messaging = FirebaseMessaging.instance;

Future<String> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return 'done';
  } catch (error) {
    return error;
  }
}

User checkUserLoginStatus() {
  if (_auth.currentUser != null) {
    return _auth.currentUser;
  } else {
    return null;
  }
}

Future<FirebaseMessaging> setUpNotifications() async {
  NotificationSettings settings = await _messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  print('User granted permission: ${settings.authorizationStatus}');
  return _messaging;
}


