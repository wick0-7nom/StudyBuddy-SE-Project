import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();

  // IMPORTANT:
  // For normal FCM notification messages, Android itself
  // displays the notification in the system notification tray.
  //
  // We don't need to manually create a local notification here.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'study_buddy_channel',
    'Study Buddy Notifications',
    description: 'Study Buddy App Notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    // -----------------------------
    // LOCAL NOTIFICATIONS
    // -----------------------------

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );

    final androidImplementation =
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        _channel,
      );

      await androidImplementation.requestNotificationsPermission();
    }

    // -----------------------------
    // FIREBASE MESSAGING
    // -----------------------------

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android foreground behavior
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // -----------------------------
    // GET FCM TOKEN
    // -----------------------------

    final token = await messaging.getToken();

    print('======================================');
    print('FCM TOKEN:');
    print(token);
    print('======================================');

    // Token can change, so listen for changes.
    FirebaseMessaging.instance.onTokenRefresh.listen(
          (newToken) {
        print('NEW FCM TOKEN: $newToken');

        // Later we can save this token to Firestore.
      },
    );

    // -----------------------------
    // FOREGROUND FCM
    // -----------------------------

    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) {
        print('FCM MESSAGE RECEIVED');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');

        final notification = message.notification;

        if (notification != null) {
          showNotification(
            id: DateTime.now()
                .millisecondsSinceEpoch
                .remainder(2147483647),
            title: notification.title ?? 'Study Buddy',
            body: notification.body ?? '',
          );
        }
      },
    );
  }

  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'study_buddy_channel',
      'Study Buddy Notifications',
      channelDescription: 'Study Buddy App Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}