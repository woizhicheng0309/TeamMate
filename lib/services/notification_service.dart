import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  /// 初始化 OneSignal
  Future<void> initialize() async {
    if (_initialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null || appId.isEmpty) {
      return;
    }

    try {
      // 初始化 OneSignal
      OneSignal.initialize(appId);

      // 請求通知權限
      await OneSignal.Notifications.requestPermission(true);

      // 設置通知點擊處理
      OneSignal.Notifications.addClickListener((event) {
        _handleNotificationOpened(event);
      });

      // 設置前台通知處理
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
      });

      _initialized = true;
    } catch (e) {
      // Silent fail on initialization
    }
  }

  /// 設置用戶 ID（登入時調用）
  Future<void> setUserId(String userId) async {
    try {
      // 使用 setExternalUserId 以便 Edge Function 能正確發送通知
      await OneSignal.login(userId);
    } catch (e) {
      // Silent fail
    }
  }

  /// 登出用戶
  Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      // Silent fail
    }
  }

  /// 獲取訂閱 ID
  String? getSubscriptionId() {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      return null;
    }
  }

  /// 檢查通知權限
  Future<bool> hasPermission() async {
    try {
      return await OneSignal.Notifications.permission;
    } catch (e) {
      return false;
    }
  }

  /// 請求通知權限
  Future<bool> requestPermission() async {
    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      return false;
    }
  }

  /// 添加用戶標籤（用於分組推送）
  Future<void> addTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
    } catch (e) {
      // Silent fail
    }
  }

  /// 處理通知點擊
  void _handleNotificationOpened(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;

    if (data != null && data.containsKey('type')) {
      final type = data['type'];

      switch (type) {
        case 'chat':
          final chatId = data['chat_id'];
          // 這裡可以添加導航邏輯
          break;

        case 'activity':
          final activityId = data['activity_id'];
          // 這裡可以添加導航邏輯
          break;

        default:
        // Unknown notification type
      }
    }
  }
}
