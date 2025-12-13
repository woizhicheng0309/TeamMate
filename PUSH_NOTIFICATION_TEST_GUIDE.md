# 📱 推送通知功能測試指南

## ✅ 已完成的集成

### 1. **應用端集成** ✅
- ✅ NotificationService - 處理 OneSignal 初始化和通知
- ✅ main.dart - 應用啟動時自動初始化 OneSignal
- ✅ AuthService - 登入時自動設置 OneSignal 用戶 ID，登出時清除
- ✅ ChatService - 發送消息時自動發送推送通知

### 2. **後端集成** ✅
- ✅ Supabase Edge Function (send-push-notification)
- ✅ OneSignal API Key 已設置在 Supabase Secrets (TeamMate_api)

### 3. **配置文件** ✅
- ✅ .env 中的 ONESIGNAL_APP_ID: 1d897905-0929-48c9-8c25-9bea2e54966f

---

## 🎯 如何測試推送通知

### 方法 1：測試聊天消息通知（最簡單）

#### 步驟：
1. **準備兩個測試帳號**
   - 在模擬器上登入帳號 A
   - 在另一個設備或瀏覽器登入帳號 B

2. **發送消息**
   - 帳號 A 向帳號 B 發送聊天消息
   - **帳號 B 的設備會收到推送通知** ✅

3. **查看通知**
   - 確保帳號 B 的應用在背景或已關閉
   - 通知會顯示: "新消息 - [帳號 A名稱]: [消息內容]"

---

### 方法 2：使用 OneSignal Dashboard 手動發送

#### 步驟：

1. **獲取用戶 ID**
   ```dart
   // 在應用中獲取當前用戶 ID
   final userId = Supabase.instance.client.auth.currentUser?.id;
   print('用戶 ID: $userId');
   ```

2. **登入 OneSignal Dashboard**
   - 訪問: https://app.onesignal.com
   - 選擇應用: TeamMate (1d897905-0929-48c9-8c25-9bea2e54966f)

3. **發送測試通知**
   - 點擊 **"Messages"** → **"New Push"**
   - 填寫標題和內容
   - 在 "Audience" 選擇 **"Send to Users Based on Filters"**
   - 添加過濾器: `User Tag` → `external_id` **IS** `[您的用戶 ID]`
   - 點擊 **"Send Message"**

4. **接收通知**
   - 關閉或切換應用到背景
   - 等待 3-10 秒，應該會收到通知

---

### 方法 3：從 Flutter 應用直接調用 Edge Function

#### 在任意 Service 中添加：

```dart
Future<void> testPushNotification() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    print('請先登入');
    return;
  }

  try {
    final response = await Supabase.instance.client.functions.invoke(
      'send-push-notification',
      body: {
        'userId': userId,
        'title': '🎉 測試通知',
        'message': '如果你看到這條通知，推送功能正常！',
        'type': 'test',
        'data': {'timestamp': DateTime.now().toIso8601String()},
      }
    );
    
    print('✅ 通知發送成功: ${response.data}');
  } catch (e) {
    print('❌ 發送失敗: $e');
  }
}
```

---

## 🚀 部署 Supabase Edge Function

### 前置要求：
```bash
# 安裝 Supabase CLI
npm install -g supabase

# 登入
supabase login
```

### 部署步驟：

```bash
# 1. 進入項目目錄
cd D:\FlutterProjects\TeamMate

# 2. 鏈接到 Supabase 項目
supabase link --project-ref your-project-ref

# 3. 部署 Edge Function
supabase functions deploy send-push-notification

# 4. 確認部署成功
supabase functions list
```

### 驗證 Secret 已設置：
在 Supabase Dashboard:
- Edge Functions → Secrets
- 確認 `TeamMate_api` 已設置（您已完成 ✅）

---

## 📋 當前功能

### 自動推送場景：

#### 1. **聊天消息通知** ✅
- 當收到新聊天消息時
- 標題: "新消息"
- 內容: "[發送者名稱]: [消息內容]"
- 數據: `{type: 'chat', chat_id: '...', sender_id: '...'}`

#### 2. **可擴展的場景**（未實現，但已預留接口）：
- 活動邀請通知
- 活動更新通知
- 好友請求通知
- 系統通知

---

## 🔍 調試檢查清單

### 應用啟動時：
```
✅ OneSignal 初始化成功
✅ supabase.supabase_flutter: INFO: ***** Supabase init completed *****
```

### 用戶登入後：
```
✅ OneSignal 用戶 ID 已設置: [user-id]
```

### 發送消息時：
```
✅ 推送通知已發送給用戶: [receiver-id]
```

### 如果看到錯誤：
```
⚠️ 發送推送通知失敗: [error]
```
- 檢查 Edge Function 是否已部署
- 檢查 TeamMate_api secret 是否正確
- 檢查接收者是否已登入並設置了 OneSignal ID

---

## 📱 通知顯示行為

### Android：
- **應用在背景/關閉**: 通知顯示在系統通知欄 ✅
- **應用在前台**: 通知橫幅顯示（已配置 display()）

### 通知點擊：
- 點擊通知會打開應用
- 控制台會輸出: `📱 通知被點擊: {...}`
- 可根據 `type` 字段導航到相應頁面

---

## 🎨 自定義通知內容

### 發送不同類型的通知：

```dart
// 聊天通知
await Supabase.instance.client.functions.invoke(
  'send-push-notification',
  body: {
    'userId': receiverId,
    'title': '新消息',
    'message': '$senderName: $content',
    'type': 'chat',
    'data': {'chat_id': chatId}
  }
);

// 活動通知
await Supabase.instance.client.functions.invoke(
  'send-push-notification',
  body: {
    'userId': participantId,
    'title': '活動更新',
    'message': '您參加的 $activityName 有更新',
    'type': 'activity',
    'data': {'activity_id': activityId}
  }
);

// 系統通知
await Supabase.instance.client.functions.invoke(
  'send-push-notification',
  body: {
    'userId': userId,
    'title': '系統通知',
    'message': '您有新的好友請求',
    'type': 'friend_request',
    'data': {'request_id': requestId}
  }
);
```

---

## ✅ 完成狀態

- ✅ OneSignal 配置完成
- ✅ 應用端集成完成
- ✅ 聊天消息推送完成
- ⚠️ Edge Function 需要部署
- ⏳ 其他通知類型可按需添加

---

## 🆘 常見問題

### Q: 沒有收到通知？
**檢查：**
1. 通知權限是否已授權
2. 用戶是否已登入
3. Edge Function 是否已部署
4. 應用是否在背景（前台通知可能不顯示）
5. 檢查應用日誌是否有錯誤

### Q: 如何測試多個用戶？
**方法：**
1. 使用模擬器 + 真機
2. 使用模擬器 + Web 瀏覽器
3. 使用兩個不同的模擬器

### Q: 推送延遲多久？
**一般情況：**
- OneSignal 處理: 1-3 秒
- 網絡傳輸: 2-5 秒
- 總延遲: 通常在 5-10 秒內

---

## 🎉 測試成功標誌

當您完成以下測試，表示推送功能完全正常：

1. ✅ 應用啟動時看到 "OneSignal 初始化成功"
2. ✅ 登入後看到 "OneSignal 用戶 ID 已設置"
3. ✅ 發送消息後看到 "推送通知已發送給用戶"
4. ✅ 接收方收到系統通知
5. ✅ 點擊通知可以打開應用

恭喜！您的推送通知功能已完全運作！🎊
