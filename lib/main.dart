// main.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:TRIPSY/splash_screen.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'EventDetailsPage.dart';
import 'location_details_page.dart';
import 'dart:convert';
import 'notifications/notification_storage.dart';
import 'notifications/notification_model.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  try {
    await NotificationStorage.init();
    final AppNotification appNotif = AppNotification.fromFcmData(
      id:
          (message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString()),
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      receivedAt: DateTime.now(),
    );
    await NotificationStorage.add(appNotif);
  } catch (_) {}
}

// Flutter Local Notifications instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global navigator key to enable navigation from notification handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      try {
        final String? payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final Map<String, dynamic> data =
            jsonDecode(payload) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (e, st) {
        print('Error handling local notification tap: $e');
        print(st);
      }
    },
  );
}

Future<void> _createDefaultNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel', // نفس id الموجود في AndroidManifest.xml
    'Default Notifications',
    description: 'Used for default notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

void requestPermission() async {
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);
  print('User granted permission: ${settings.authorizationStatus}');
}

Future<void> _initFcmToken() async {
  try {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      print('FCM Token refreshed: $newToken');
    });
  } catch (e) {
    print('Error fetching FCM token: $e');
  }
}

// ✅ إضافة listener لعرض الإشعارات في foreground
void setupForegroundNotificationListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message in foreground: ${message.notification?.title}');

    if (message.notification != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'default_channel',
            'Default Notifications',
            channelDescription: 'Used for default notifications',
            importance: Importance.high,
            // priority: Priority.high,
            playSound: true,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      try {
        // Save to local storage
        final AppNotification appNotif = AppNotification.fromFcmData(
          id:
              (message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString()),
          title: message.notification?.title,
          body: message.notification?.body,
          data: message.data,
          receivedAt: DateTime.now(),
        );
        NotificationStorage.add(appNotif);

        flutterLocalNotificationsPlugin.show(
          message.notification.hashCode,
          message.notification?.title,
          message.notification?.body,
          platformDetails,
          payload: jsonEncode(message.data),
        );
      } catch (e, st) {
        print('Error showing local notification: $e');
        print(st);
      }
    }
  });
}

// Navigate to the appropriate screen based on payload
void _handleNotificationNavigation(Map<String, dynamic> data) {
  try {
    final String? type = (data['type'] ?? data['notification_type'])
        ?.toString();
    final String? id = (data['id'] ?? data['target_id'])?.toString();

    if (type == null) return; // plain notification: no navigation

    if ((type == 'location' || type == 'place') &&
        id != null &&
        id.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => LocationDetailsPage(locationId: id)),
      );
      return;
    }

    if (type == 'event' && id != null && id.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: id)),
      );
      return;
    }
  } catch (e, st) {
    print('Error navigating from notification payload: $e');
    print(st);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationStorage.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initializeLocalNotifications();
  await _createDefaultNotificationChannel();

  // ✅ طلب صلاحيات الإشعارات
  requestPermission();

  // ✅ جلب token
  await _initFcmToken();

  // ✅ تفعيل استقبال الإشعارات foreground
  setupForegroundNotificationListener();

  // ✅ التنقل عند الضغط على الإشعار من الخلفية
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    try {
      final AppNotification appNotif = AppNotification.fromFcmData(
        id:
            (message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString()),
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
        receivedAt: DateTime.now(),
      );
      NotificationStorage.add(appNotif);
    } catch (_) {}
    _handleNotificationNavigation(message.data);
  });

  // ✅ معالجة فتح التطبيق عبر إشعار (terminated)
  final RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  final Map<String, dynamic>? initialData = initialMessage?.data;
  if (initialData != null && initialData.isNotEmpty) {
    try {
      final AppNotification appNotif = AppNotification.fromFcmData(
        id:
            (initialMessage?.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString()),
        title: initialMessage?.notification?.title,
        body: initialMessage?.notification?.body,
        data: initialData,
        receivedAt: DateTime.now(),
      );
      NotificationStorage.add(appNotif);
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation(initialData);
    });
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'TRIPSY',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
    );
  }
}