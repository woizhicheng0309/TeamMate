# 推送通知配置指南

## 当前状态
- ✅ Edge Function 已部署
- ✅ OneSignal 集成代码已添加
- ⏳ 需要配置 OneSignal 凭证

## 配置步骤

### 1. 获取 OneSignal 凭证

访问 [OneSignal Dashboard](https://dashboard.onesignal.com) 并：
1. 创建新应用或选择现有应用
2. 复制 **App ID**
3. 进入 Settings → Keys & IDs，复制 **REST API Key**

### 2. 在 Supabase 中设置环境变量

#### 方式 A：通过 Supabase Dashboard
1. 打开 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择你的项目：`mnmljxygcvpgkvnshchx`
3. 进入 Edge Functions → send-push-notification
4. 点击 "Configuration" 或 "Secrets"
5. 添加以下环境变量：
   - `ONESIGNAL_APP_ID`: 你的 OneSignal App ID
   - `ONESIGNAL_REST_API_KEY`: 你的 OneSignal REST API Key

#### 方式 B：通过 CLI
```bash
cd /Users/woizhicheng/Desktop/TeamMate/teammate_app

# 设置环境变量
supabase secrets set ONESIGNAL_APP_ID="your_app_id"
supabase secrets set ONESIGNAL_REST_API_KEY="your_rest_api_key"

# 验证
supabase secrets list
```

### 3. 验证推送通知是否工作

1. 启动 Flutter 应用
2. 打开两个用户之间的私聊
3. 从一个用户发送消息
4. 检查日志是否显示推送通知已发送：
   ```
   ✅ 推送通知已通過 OneSignal 發送
   ```

## 故障排除

### 问题 1：推送通知未发送
- ✓ 检查环境变量是否正确设置
- ✓ 确保 OneSignal 应用已启用
- ✓ 检查用户的设备是否已注册到 OneSignal

### 问题 2：看到错误 "undefined"
- 这意味着环境变量未配置
- 在 Supabase Dashboard 中设置环境变量

### 问题 3：OneSignal 返回 403 错误
- 检查 REST API Key 是否正确
- 确保 App ID 与 REST API Key 来自同一应用

## 本地测试（可选）

如果想在本地测试 Edge Function：

```bash
cd /Users/woizhicheng/Desktop/TeamMate/teammate_app

# 启动本地 Supabase
supabase start

# 测试函数（在另一个终端）
curl -X POST http://localhost:54321/functions/v1/send-push-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "userId": "test-user-id",
    "title": "Test Notification",
    "message": "This is a test message",
    "type": "chat"
  }'
```

## 更多信息
- [OneSignal 文档](https://documentation.onesignal.com/)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
