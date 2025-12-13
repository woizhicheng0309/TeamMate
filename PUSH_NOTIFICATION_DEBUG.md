# 推送通知调试指南

## 推送通知不显示的原因排查

### 检查清单

#### 1. 确认 OneSignal 配置完整
- [ ] App ID 已在 Supabase Secrets 中配置
- [ ] REST API Key 已在 Supabase Secrets 中配置
- [ ] OneSignal 应用的 Android/iOS 推送证书已配置

#### 2. 检查应用日志
运行应用并查看日志，应该看到：
```
✅ OneSignal 初始化成功
✅ OneSignal 用户 ID 已设置: [用户ID]
✅ 推送通知已通过 OneSignal 发送
```

#### 3. 验证用户 ID 匹配
- 确保发送方和接收方都登录了应用
- 检查 Flutter 日志中的用户 ID 是否正确

#### 4. 检查 OneSignal Dashboard
1. 进入 [OneSignal Dashboard](https://dashboard.onesignal.com)
2. 选择你的应用
3. 进入 Audience → Users
4. 检查是否能看到你的测试用户

#### 5. 手动测试推送通知
在 OneSignal Dashboard 中：
1. 进入 New Message → Create
2. 选择你的用户
3. 发送测试通知
4. 检查应用是否收到通知

### 常见问题

**问题 1：OneSignal Dashboard 中看不到用户**
- 原因：用户未正确调用 `OneSignal.login(userId)`
- 解决：确保在登入后调用了 `NotificationService().setUserId(userId)`

**问题 2：通知被发送但没有显示**
- 原因：可能是前台通知需要主动调用 `display()`
- 检查：NotificationService 中的 `addForegroundWillDisplayListener`

**问题 3：看到 OneSignal error: Message Notifications must have...**
- 原因：通知内容没有英文翻译
- 已修复：现在 headings 和 contents 包含 `en` 和 `zh`

### 调试步骤

1. **打开两个模拟器实例**
   ```bash
   flutter run --verbose  # 查看详细日志
   ```

2. **用不同的账户登录**
   - 账户 A：账户 B 登出后用账户 A 登入
   - 账户 B：打开第二个模拟器，用账户 B 登入

3. **发送消息测试**
   - 账户 A 发送消息给账户 B
   - 检查账户 B 是否收到通知

4. **查看 Edge Function 日志**
   - 打开 [Supabase Dashboard](https://supabase.com/dashboard/project/mnmljxygcvpgkvnshchx/functions)
   - 点击 send-push-notification
   - 查看执行日志

### 如果还是不行

请收集以下信息：
1. Flutter 日志中的完整错误信息
2. Edge Function 的执行日志
3. OneSignal Dashboard 中的用户列表
4. 测试账户的用户 ID

然后我们可以进一步调试。
