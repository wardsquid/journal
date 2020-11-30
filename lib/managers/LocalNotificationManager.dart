import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File, Platform;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationPlugin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var initializationSettings;
  var tokyo;

  NotificationPlugin._() {
    init();
  }

  init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isIOS) {
      _requestIOSPermission();
    }

    initializePlatformSpecifics();
    tz.initializeTimeZones();
    tokyo = tz.getLocation('Japan/Tokyo');
    tz.setLocalLocation(tokyo);
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

  Future<void> showDailyAtTime(TimeOfDay reminderTime) async {
    //var time = tz.DateTime()
    // var localTime = tz.DateTime(2010, 1, 1);
    final now = DateTime.now();
    final dt = DateTime(
        now.year, now.month, now.day, reminderTime.hour, reminderTime.minute);
    var time = tz.TZDateTime.from(dt, tokyo);
    // var time = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    var androidChannelSpecifics = AndroidNotificationDetails(
        'Channel-1', 'Reminder', 'For custom reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        // largeIcon: DrawableResourceAndroidBitmap('default_icon'),
        styleInformation: DefaultStyleInformation(true, true));

    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        '<b>Dear diary...</b>',
        "Ready to write today's entry?",
        time,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Custom reminder');
  }
}

//   Future<void> showNotification() async {
//     var androidChannelSpecifics = AndroidNotificationDetails(
//         'CHANNEL_ID', 'CHANNEL_NAME', 'CHANNEL_DESCRIPTION',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: true,
//         styleInformation: DefaultStyleInformation(true, true));

//     var iosChannelSpecifics = IOSNotificationDetails();
//     var platformChannelSpecifics = NotificationDetails(
//         android: androidChannelSpecifics, iOS: iosChannelSpecifics);
//     await flutterLocalNotificationsPlugin.show(0, '<b>Dear diary...</b>',
//         "Ready to write today's entry?", platformChannelSpecifics,
//         payload: 'Custom reminder');
//   }
// }

NotificationPlugin notificationPlugin = NotificationPlugin._();
