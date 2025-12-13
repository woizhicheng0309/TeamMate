// Supabase Edge Function - 發送 OneSignal 推送通知
// 部署指令: supabase functions deploy send-push-notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 處理 CORS preflight 請求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 從 Supabase secrets 獲取 OneSignal API key
    const ONESIGNAL_API_KEY = Deno.env.get('TeamMate_api')!
    const ONESIGNAL_APP_ID = "1d897905-0929-48c9-8c25-9bea2e54966f"

    // 解析請求體
    const { userId, title, message, type, data } = await req.json()

    // 驗證必需參數
    if (!userId || !title || !message) {
      return new Response(
        JSON.stringify({ 
          success: false,
          error: '缺少必需參數: userId, title, message' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`📤 發送通知到用戶: ${userId}`)
    console.log(`標題: ${title}`)
    console.log(`內容: ${message}`)

    // 發送推送通知到 OneSignal
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_API_KEY}`
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        target_channel: "push",
        include_aliases: {
          external_id: [userId]
        },
        headings: { en: title },
        contents: { en: message },
        data: {
          type: type || 'general',
          timestamp: new Date().toISOString(),
          ...data
        }
      })
    })

    const result = await response.json()

    if (!response.ok) {
      console.error('❌ OneSignal API 錯誤:', result)
      throw new Error(JSON.stringify(result))
    }

    console.log('✅ 通知發送成功')

    return new Response(
      JSON.stringify({ 
        success: true, 
        result,
        message: '通知已成功發送'
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('❌ 發送通知錯誤:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

/* 
使用範例：

1. 從 Flutter 應用調用：

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> sendPushNotification({
  required String userId,
  required String title,
  required String message,
  String? type,
  Map<String, dynamic>? data,
}) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'send-push-notification',
      body: {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
      }
    );
    
    print('通知發送結果: ${response.data}');
  } catch (e) {
    print('發送通知錯誤: $e');
  }
}
```

2. 聊天消息通知：

```dart
await sendPushNotification(
  userId: receiverId,
  title: '新消息',
  message: '$senderName: $messageContent',
  type: 'chat',
  data: {'chat_id': chatId},
);
```

3. 活動通知：

```dart
await sendPushNotification(
  userId: participantId,
  title: '活動更新',
  message: '您參加的活動有新的更新',
  type: 'activity',
  data: {'activity_id': activityId},
);
```

部署步驟：
1. 安裝 Supabase CLI: npm install -g supabase
2. 登入: supabase login
3. 鏈接項目: supabase link --project-ref your-project-ref
4. 部署: supabase functions deploy send-push-notification
5. 確認 TeamMate_api secret 已在 Supabase Dashboard 設置
*/
