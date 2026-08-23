import 'dart:convert';
import 'dart:io'; // ✅ Changed from 'dart:io' show Platform
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // ✅ Add this import
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/navigation_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';

// ✅ Top-level handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.messageId}');
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isInitialized = false;
  bool _isAppInForeground = true;

  static const String _chatChannelId = 'chat_messages';
  static const String _orderChannelId = 'order_updates';
  static const String _paymentChannelId = 'payment_updates';
  static const String _systemChannelId = 'system_updates';

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    debugPrint('📱 Initializing push notification service...');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _initLocalNotifications();
    await _setupToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Opened from notification: ${message.data}');
      _handleNotificationTap(message.data);
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📩 Launched from terminated state: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });

    debugPrint('✅ Push notification service initialized');
  }

  void setAppInForeground(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'fcm_default_channel',
          'General',
          description: 'General notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _chatChannelId,
          'Chat Messages',
          description: 'Notifications for new chat messages',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _orderChannelId,
          'Order Updates',
          description: 'Notifications for order status changes',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _paymentChannelId,
          'Payment Updates',
          description: 'Notifications for payment status',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _systemChannelId,
          'System Updates',
          description: 'General system notifications',
          importance: Importance.defaultImportance,
        ),
      );
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!) as Map<String, dynamic>;
            _handleNotificationTap(data);
          } catch (e) {
            debugPrint('❌ Failed to parse notification payload: $e');
          }
        }
      },
    );
  }

  Future<void> _setupToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        await _registerToken(token);
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('📱 FCM Token refreshed: $newToken');
        _registerToken(newToken);
      });
    } catch (e) {
      debugPrint('⚠️ Could not get FCM token: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final authToken = await storageService.getAuthToken();
      if (authToken == null) return;

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
        debugPrint('✅ Device token registered successfully');
      }
    } catch (e) {
      debugPrint('❌ Failed to register token: $e');
    }
  }

  // ✅ UPDATED: Downloads image for foreground Big Picture display
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type']?.toString() ?? 'system';
    final imageUrl = message.data['imageUrl']?.toString();

    if ((type == 'message' || type == 'new_message') && _isAppInForeground) {
      debugPrint('📩 Skipping local notification - app in foreground');
      return;
    }

    final androidChannelId = _getChannelIdForType(type);
    AndroidNotificationDetails? androidPlatformChannelSpecifics;

    // ✅ If there's an image URL, download it and show as Big Picture
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final messageId = message.messageId ?? 'default';
          final file = File(
            '${tempDir.path}/notification_image_$messageId.jpg',
          );
          await file.writeAsBytes(response.bodyBytes);

          androidPlatformChannelSpecifics = AndroidNotificationDetails(
            androidChannelId,
            _getChannelNameForType(type),
            channelDescription: _getChannelDescriptionForType(type),
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(file.path),
              hideExpandedLargeIcon: true,
              contentTitle: notification.title,
              summaryText: notification.body,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to download notification image: $e');
      }
    }

    // ✅ Fallback if no image or download failed
    androidPlatformChannelSpecifics ??= AndroidNotificationDetails(
      androidChannelId,
      _getChannelNameForType(type),
      channelDescription: _getChannelDescriptionForType(type),
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(message.data),
    );
  }

  String _getChannelIdForType(String type) {
    switch (type) {
      case 'message':
      case 'new_message':
        return _chatChannelId;
      case 'order':
        return _orderChannelId;
      case 'payment':
        return _paymentChannelId;
      default:
        return _systemChannelId;
    }
  }

  String _getChannelNameForType(String type) {
    switch (type) {
      case 'message':
      case 'new_message':
        return 'Chat Messages';
      case 'order':
        return 'Order Updates';
      case 'payment':
        return 'Payment Updates';
      default:
        return 'System Updates';
    }
  }

  String _getChannelDescriptionForType(String type) {
    switch (type) {
      case 'message':
      case 'new_message':
        return 'Notifications for new chat messages';
      case 'order':
        return 'Notifications for order status changes';
      case 'payment':
        return 'Notifications for payment status';
      default:
        return 'General system notifications';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('📩 Notification tapped: $data');

    final type = data['type']?.toString();
    final actionLink = data['actionLink']?.toString();
    final context = NavigationService.navigatorKey.currentContext;

    if (context == null) {
      debugPrint('❌ No context available for navigation');
      return;
    }

    // ✅ 1. PRIORITY: Handle actionLink if it exists (e.g., /products/xyz, /orders/123)
    if (actionLink != null && actionLink.isNotEmpty) {
      debugPrint('🔗 Navigating via actionLink: $actionLink');
      final uri = Uri.tryParse(actionLink);
      if (uri != null) {
        final segments = uri.path
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList();
        if (segments.isNotEmpty) {
          final resource = segments[0];
          final id = segments.length >= 2 ? segments[1] : null;

          if (resource == 'products' && id != null) {
            NavigationService.navigateTo(
              '/product-details',
              arguments: {'productId': id},
            );
            return;
          } else if (resource == 'orders' && id != null) {
            NavigationService.navigateTo(
              '/order-details',
              arguments: {'orderId': id},
            );
            return;
          } else if (resource == 'chat' && id != null) {
            NavigationService.navigateTo(
              '/chat-room',
              arguments: {'partnerId': id},
            );
            return;
          } else if (resource == 'home') {
            NavigationService.popToRoot();
            return;
          } else if (resource == 'admin') {
            NavigationService.navigateTo('/admin');
            return;
          }
        }
      }
    }

    // ✅ 2. FALLBACK: Type-based navigation if no actionLink or parsing failed
    switch (type) {
      case 'message':
      case 'new_message':
        final senderId = data['senderId'];
        if (senderId != null) {
          NavigationService.navigateTo(
            '/chat-room',
            arguments: {'partnerId': senderId},
          );
        }
        break;

      case 'order':
      case 'payment':
        final orderId = data['orderId'];
        if (orderId != null) {
          NavigationService.navigateTo(
            '/order-details',
            arguments: {'orderId': orderId},
          );
        }
        break;

      default:
        // If no actionLink and no specific type match, go to notifications
        NavigationService.navigateTo('/notifications');
        break;
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> unregisterToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      final storageService = GetIt.instance<StorageService>();
      final authToken = await storageService.getAuthToken();
      if (authToken == null) return;

      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/chat/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': token}),
      );

      debugPrint('✅ Device token unregistered');
    } catch (e) {
      debugPrint('❌ Failed to unregister token: $e');
    }
  }
}
