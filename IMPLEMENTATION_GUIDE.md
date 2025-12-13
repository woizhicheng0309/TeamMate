# 活動加入功能與群組聊天整合

## 已完成的功能

### 1. 活動詳情頁面 (ActivityDetailScreen)
- ✅ 顯示完整活動資訊（日期、地點、人數、時長等）
- ✅ 顯示參與者列表，標註創建者
- ✅ 加入/退出活動按鈕
- ✅ 活動已滿或已加入時的狀態顯示
- ✅ 點擊活動卡片可進入詳情頁面

### 2. 數據庫服務更新 (DatabaseService)
```dart
// 新增的方法：
- joinActivity(activityId, userId) - 加入活動並更新參與人數
- leaveActivity(activityId, userId) - 退出活動並更新參與人數
- getActivityParticipants(activityId) - 獲取活動所有參與者資訊
```

### 3. 聊天服務更新 (ChatService)
```dart
// 更新的方法：
- getUserChats(userId) - 使用新的 participants 欄位過濾
- getOrCreateChat(user1Id, user2Id) - 創建私聊，使用新的資料結構
- getOrCreateGroupChat(activityId, groupName, participantIds) - 創建/更新群組聊天
```

## 需要完成的步驟

### 第一步：更新資料庫結構 ⚠️ **重要**

1. 登入 Supabase Dashboard: https://supabase.com/dashboard
2. 選擇你的專案 (mnmljxygcvpgkvnshchx)
3. 點擊左側選單的 "SQL Editor"
4. 點擊 "New Query"
5. 複製 `database_migrations/03_update_chats_schema.sql` 的內容
6. 貼上並執行

**這個腳本會：**
- 添加 `type`、`name`、`participants`、`avatar_url`、`unread_count` 欄位到 chats 表
- 創建索引以提高查詢效率
- 設置 Row Level Security (RLS) 策略
- 更新 messages 表的結構

### 第二步：測試功能流程

1. **測試活動加入：**
   ```
   登入 App → 瀏覽活動 → 點擊活動卡片 → 查看詳情 → 點擊「加入活動」
   ```
   - 確認參與人數增加
   - 確認自己出現在參與者列表中
   - 確認按鈕變成「退出活動」

2. **測試群組聊天自動創建：**
   ```
   加入活動後 → 進入聊天頁面 → 查看是否出現以活動名稱命名的群組聊天
   ```
   - 確認群組聊天名稱正確
   - 確認所有參與者都在群組中
   - 嘗試發送訊息

3. **測試多人加入：**
   ```
   使用另一個帳號 → 加入同一活動 → 檢查群組聊天參與者列表是否更新
   ```

4. **測試退出活動：**
   ```
   點擊「退出活動」→ 確認對話框 → 確認退出
   ```
   - 確認參與人數減少
   - 確認自己從參與者列表移除
   - 群組聊天應該仍然保留（可以選擇是否要實現自動移除）

### 第三步：私聊功能實現（待完成）

目前 `ChatService.getOrCreateChat()` 已經準備好，但需要：

1. **在參與者列表添加點擊事件：**
   ```dart
   // 在 activity_detail_screen.dart 的參與者列表 ListTile 中添加
   onTap: () async {
     final currentUserId = _authService.currentUser?.id;
     if (currentUserId != null && participant['id'] != currentUserId) {
       final chat = await _chatService.getOrCreateChat(
         currentUserId, 
         participant['id']
       );
       // 導航到聊天頁面
       Navigator.push(context, MaterialPageRoute(
         builder: (context) => ChatScreen(chat: chat),
       ));
     }
   }
   ```

2. **創建或更新聊天頁面：**
   - 需要一個 `ChatScreen` 來顯示訊息
   - 使用 `ChatService.getChatMessages()` 串流顯示訊息
   - 使用 `ChatService.sendMessage()` 發送訊息

## 資料結構說明

### chats 表（新結構）
```sql
- id: UUID (主鍵)
- type: TEXT ('private' 或 'group')
- activity_id: UUID (對於群組聊天，關聯到活動)
- name: TEXT (聊天名稱)
- participants: TEXT[] (參與者 ID 陣列)
- avatar_url: TEXT (可選)
- last_message: TEXT
- last_message_time: TIMESTAMP
- unread_count: INTEGER
- created_at: TIMESTAMP
```

### participants 表
```sql
- activity_id: UUID (外鍵 -> activities.id)
- user_id: UUID (外鍵 -> users.id)
- joined_at: TIMESTAMP
```

## 下一步開發建議

1. ✅ 完成資料庫遷移
2. 🔄 測試活動加入/退出功能
3. 🔄 測試群組聊天自動創建
4. ⏳ 實現私聊功能（點擊參與者開始聊天）
5. ⏳ 創建完整的聊天介面 (ChatScreen)
6. ⏳ 添加通知功能（新訊息提醒）
7. ⏳ 優化聊天列表 UI（顯示頭像、最後訊息等）

## 常見問題

**Q: 如果用戶退出活動，群組聊天會怎樣？**
A: 目前群組聊天會保留。如果需要自動移除，可以在 `leaveActivity` 方法中添加邏輯更新群組聊天的 participants。

**Q: 創建活動的人也需要加入嗎？**
A: 是的，創建者在創建活動時會自動加入到 participants 表（需要在 CreateActivityScreen 中實現）。

**Q: 群組聊天的參與者列表會自動更新嗎？**
A: 是的，每次有人加入活動時，`getOrCreateGroupChat` 會更新 participants 陣列。

## 檔案位置

- 活動詳情頁面: `lib/screens/activity_detail_screen.dart`
- 資料庫服務: `lib/services/database_service.dart`
- 聊天服務: `lib/services/chat_service.dart`
- 資料庫遷移: `database_migrations/03_update_chats_schema.sql`
