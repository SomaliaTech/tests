import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/storage/storage_service.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> init() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initLocalNotifications();

    // Get FCM token
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        // ✅ Try to register - will succeed if user is already logged in
        await _registerToken(token);
      }
    } catch (e) {
      print('⚠️ Could not get FCM token: $e');
    }

    // ✅ Listen for token refresh and register immediately
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('📱 FCM Token refreshed: $newToken');
      _registerToken(newToken);
    });
    // Handle foreground messages
    // In PushNotificationService - already have this, but make sure it's working
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message: ${message.notification?.title}');
      // ✅ Always show local notification even if app is in foreground
      _showLocalNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Opened from notification: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Handle terminated app
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('📱 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // ✅ FIX: Parse the payload
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!) as Map<String, dynamic>;
            _handleNotificationTap(data);
          } catch (e) {
            print('❌ Failed to parse notification payload: $e');
          }
        }
      },
    );
  }

  Future<void> _registerToken(String token) async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final authToken = await storageService.getAuthToken();

      if (authToken == null) {
        print('❌ No auth token, cannot register device token');
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': token, 'platform': platform}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('📱 Device token registered successfully');
      } else {
        print('❌ Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to register token: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(message.data),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('📩 Notification tapped: $data');

    // Navigate to chat screen based on notification data
    if (data['type'] == 'new_message') {
      final senderId = data['senderId'];
      if (senderId != null) {
        // You can use a global navigator key to navigate
        print('📩 Navigate to chat with: $senderId');
        // Example:
        // navigatorKey.currentState?.push(
        //   MaterialPageRoute(
        //     builder: (_) => ChatRoomScreen(
        //       partnerId: senderId,
        //       partnerName: data['title'] ?? 'Chat',
        //     ),
        //   ),
        // );
      }
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
