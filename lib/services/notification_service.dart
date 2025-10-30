import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view/widget/get_notification_screen.dart';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // String uid = '';
  //
  // void loadUserData() async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   uid = prefs.getString('uid') ?? '';
  // }
  Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobile'); // जो key आपने save की थी
  }

  //for notification request
  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("user granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("user provisional granted permission");
    } else {
      Get.snackbar(
        "Notification permission denied",
        "Please allow notification to reciev updates.",
        snackPosition: SnackPosition.BOTTOM,
      );
      Future.delayed(Duration(seconds: 2), () {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      });
    }
  }

  void initLocalNotification(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitSettings = const AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    var iosInitSettings = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
        handleMessage(context, message);
      },
    );
  }

  //firebase init
  //jab hmari app working me rhegi tb ye notification kaam karegi
  void firebaseInit(BuildContext context) {
    // Only listen once
    FirebaseMessaging.onMessage.listen((message) async {
      RemoteNotification? notification = message.notification;
      if (kDebugMode) {
        print("notification title: ${notification?.title}");
        print("notification body: ${notification?.body}");
      }

      if (Platform.isIOS) {
        iosForgroundMessage();
      }

      if (Platform.isAndroid) {
        showNotification(message);
        await saveNotificationToFirebase(message);
      }
    });
  }

  // Initialize local notifications only once
  Future<void> initializeLocalNotificationsOnce() async {
    var androidInitSettings = const AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    var iosInitSettings = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> saveNotificationToFirebase(RemoteMessage message) async {
    String? mobile = await getMobile();
    if (mobile == null || mobile.isEmpty) return;

    // Use consistent ID for duplicate prevention
    final msgId =
        message.messageId ??
        "${message.notification?.title}-${message.notification?.body}";

    final ref = FirebaseFirestore.instance
        .collection('message')
        .doc(mobile)
        .collection('notifications');

    final existing = await ref.where('messageId', isEqualTo: msgId).get();
    if (existing.docs.isNotEmpty) {
      print('🔁 Skipping duplicate notification: $msgId');
      return;
    }

    await ref.add({
      'messageId': msgId,
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'sentTime':
          message.sentTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'status': 'unread',
      'mutableContent': message.mutableContent ?? false,
    });
  }

  //function to show notifications
  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      message.notification!.android!.channelId.toString(),
      message.notification!.android!.channelId.toString(),
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );

    //android settings
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id.toString(),
          channel.name.toString(),
          channelDescription: "Channel Description",
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: channel.sound,
        );
    //ios settings
    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
        );
    //merge android and ios setting
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    //show notification
    Future.delayed(Duration.zero, () {
      //popup show
      _flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title.toString(),
        message.notification!.body.toString(),
        notificationDetails,
        payload: "my_data",
      );
    });
  }

  //background and terminated
  Future<void> setupInteractMessage(BuildContext context) async {
    //background state app is open and like background
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (msg.data.isNotEmpty) {
        handleMessage(context, msg);
      }
    });

    //terminated state aap close and exist then call method
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null && message.data.isNotEmpty) {
        handleMessage(context, message);
      }
    });
  }

  //handle message
  Future<void> handleMessage(
    BuildContext context,
    RemoteMessage message,
  ) async {
    await saveNotificationToFirebase(message);
    Get.to(() => GetNotificationScreen());
    //Get.to(() => DashboardScreen());
  }

  //ios message
  Future iosForgroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}
