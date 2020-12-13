import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/Firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

final User _user = checkUserLoginStatus();
final CollectionReference _entries = getFireStoreEntriesDB();
final FirebaseStorage _storage = getStorage();
final Map<DateTime, List> entryParser = {};

Future<QuerySnapshot> fireStoreUserQuery(DateTime today) async {
  // print(today.toString());
  // print(
  //     "less than ${DateTime(today.year, today.month + 1, today.day, today.hour + 1).toString()}");
  // // print("greater than ${DateTime(today.year, today.month)}");
  return await _entries
      .where('user_id', isEqualTo: _user.uid)
      .where('timestamp',
          isGreaterThan: DateTime(
            today.year,
            today.month,
          ))
      .where('timestamp',
          isLessThan:
              DateTime(today.year, today.month + 1, today.day, today.hour + 1))
      .orderBy('timestamp', descending: true)
      .get();
}

Future<QuerySnapshot> fireStoreSharedQuery(DateTime today) async {
  return await _entries
      .where('shared_with', arrayContains: _user.email)
      .where('timestamp',
          isGreaterThan: DateTime(
            today.year,
            today.month,
          ))
      .where('timestamp',
          isLessThan:
              DateTime(today.year, today.month + 1, today.day, today.hour + 1))
      .orderBy('timestamp', descending: true)
      .get();
}

Future<String> downloadURLImage(String ownerId, String documentId) async {
  final String imageUrl =
      await _storage.ref("$ownerId/$documentId").getDownloadURL();
  return imageUrl;
}
