import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File, Platform;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'Firebase.dart';

class NotificationPlugin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var initializationSettings;
  var localLocation;

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
    localLocation = tz.getLocation('Asia/Tokyo');
    tz.setLocalLocation(localLocation);
  }

  initializePlatformSpecifics() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
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

  Future<void> showDailyAtTime(DateTime reminderTime) async {
    print("showDailyAtTime: $reminderTime");

    var now = DateTime.now();
    var dt = DateTime(
        7777, now.month, now.day, reminderTime.hour, reminderTime.minute);
    var time = tz.TZDateTime.from(reminderTime, localLocation);
    print("TZ time: $time");

    var androidChannelSpecifics = AndroidNotificationDetails(
        'Channel-1', 'Reminder', 'For custom reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        largeIcon: DrawableResourceAndroidBitmap('app_icon'),
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
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'Custom reminder');
  }
}

NotificationPlugin notificationPlugin = NotificationPlugin._();
