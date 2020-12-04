library inkling.globals;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Firebase.dart';

// bool isLoggedIn = false;
Map<String, dynamic> userProfile;

void initializeUserCaching() {
  User current = checkUserLoginStatus();
  CollectionReference userDB = getFireStoreUsersDB();
  userDB.doc(current.uid).get().then((value) => userProfile = value.data());
}

///////////////////////////////////////////////
/// import 'userInfo.dart' as inkling;
/// inkling.userProfile
///