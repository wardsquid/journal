import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<String> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return 'done';
  } catch (error) {
    return error;
  }
}

User checkUserLoginStatus () {
  if (_auth.currentUser != null) {
  return _auth.currentUser;
  }
  else {
    return null;
  }
}