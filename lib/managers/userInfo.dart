library inkling.globals;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Firebase.dart';

// bool isLoggedIn = false;
Map<String, dynamic> userProfile;
Map<String, dynamic> activeEntry;
String currentJournal;

Future<void> initializeUserCaching() async {
  currentJournal = null;
  User current = checkUserLoginStatus();
  if (current == null)
    return null;
  else {
    CollectionReference userDB = getFireStoreUsersDB();
    DocumentSnapshot userInfo = await userDB.doc(current.uid).get();
    userProfile = userInfo.data();
    updateJournal();
  }
}

void updateJournal() {
  currentJournal = userProfile['journals_list'][0].toString();
}
///////////////////////////////////////////////
/// import 'userInfo.dart' as inkling;
/// inkling.userProfile
///
