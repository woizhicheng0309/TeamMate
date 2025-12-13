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
      print('⚠️ OneSignal App ID 未在 .env 中設置');
      return;
    }

    try {
      // 初始化 OneSignal
      OneSignal.initialize(appId);

      // 請求通知權限
      await OneSignal.Notifications.requestPermission(true);

      // 設置通知點擊處理
      OneSignal.Notifications.addClickListener((event) {
        print('📱 通知被點擊: ${event.notification.jsonRepresentation()}');
        _handleNotificationOpened(event);
      });

      // 設置前台通知處理
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('📬 收到前台通知: ${event.notification.title}');
        event.notification.display();
      });

      _initialized = true;
      print('✅ OneSignal 初始化成功');
    } catch (e) {
      print('❌ OneSignal 初始化錯誤: $e');
    }
  }

  /// 設置用戶 ID（登入時調用）
  Future<void> setUserId(String userId) async {
    try {
      // 使用 setExternalUserId 以便 Edge Function 能正確發送通知
      await OneSignal.login(userId);
      print('✅ OneSignal 用戶 ID 已設置: $userId');
    } catch (e) {
      print('❌ 設置 OneSignal 用戶 ID 錯誤: $e');
    }
  }

  /// 登出用戶
  Future<void> logout() async {
    try {
      await OneSignal.logout();
      print('✅ OneSignal 用戶已登出');
    } catch (e) {
      print('❌ OneSignal 登出錯誤: $e');
    }
  }

  /// 獲取訂閱 ID
  String? getSubscriptionId() {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      print('❌ 獲取訂閱 ID 錯誤: $e');
      return null;
    }
  }

  /// 檢查通知權限
  Future<bool> hasPermission() async {
    try {
      return await OneSignal.Notifications.permission;
    } catch (e) {
      print('❌ 檢查通知權限錯誤: $e');
      return false;
    }
  }

  /// 請求通知權限
  Future<bool> requestPermission() async {
    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      print('❌ 請求通知權限錯誤: $e');
      return false;
    }
  }

  /// 添加用戶標籤（用於分組推送）
  Future<void> addTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      print('✅ OneSignal 標籤已添加: $tags');
    } catch (e) {
      print('❌ 添加標籤錯誤: $e');
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
          print('🔔 打開聊天: $chatId');
          // 這裡可以添加導航邏輯
          break;

        case 'activity':
          final activityId = data['activity_id'];
          print('🔔 打開活動: $activityId');
          // 這裡可以添加導航邏輯
          break;

        default:
          print('🔔 未知通知類型: $type');
      }
    }
  }
}
