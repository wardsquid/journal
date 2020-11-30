import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File, Platform;

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

class NotificationPlugin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var initializationSettings;

  NotificationPlugin._() {
    init();
  }

  init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isIOS) {
      _requestIOSPermission();
    }

    initializePlatformSpecifics();
  }

  initializePlatformSpecifics() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('default_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }

  _requestIOSPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        .requestPermissions(alert: true, badge: true, sound: true);
  }

  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
      onNotificationClick(payload);
    });
  }

  Future<void> showNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
        'CHANNEL_ID', 'CHANNEL_NAME', 'CHANNEL_DESCRIPTION',
        importance: Importance.max, priority: Priority.high);

    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'Test title', 'Test body', platformChannelSpecifics,
        payload: 'TEST PAYLOAD');
  }
}

NotificationPlugin notificationPlugin = NotificationPlugin._();
// Future<void> initializationSettingsAndroid() async {
//   var initializationSettingsAndroid =
//       AndroidInitializationSettings('default_icon');
//   var initializationSettingsIOS = IOSInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification:
//           (int id, String title, String body, String payload) async {});
//   var initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
//   await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//       onSelectNotification: (String payload) async {
//     if (payload != null) {
//       debugPrint('notification payload: ' + payload);
//     }
//   });
//}
