import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'Splash_Screen.dart';
import 'package:flutter/material.dart';
import 'views/LoginPage.dart';
import 'manager/Firebase.dart';
import 'Navigation.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
    //final currentUser = checkUserLoginStatus();
  runApp(MyApp());

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


