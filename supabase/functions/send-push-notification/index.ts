// Supabase Edge Function - 發送推送通知
// 部署指令: supabase functions deploy send-push-notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// OneSignal 配置
const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') || ''
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') || ''

serve(async (req) => {
  console.log('🔔 Edge Function 被調用')
  console.log('請求方法:', req.method)
  
  // 處理 CORS preflight 請求
  if (req.method === 'OPTIONS') {
    console.log('✅ CORS preflight 請求')
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📝 解析請求體...')
    const body = await req.json()
    const { userId, title, message, type, data } = body

    console.log('📊 請求數據:', { userId, title, message, type, data })

    // 驗證必需參數
    if (!userId || !title || !message) {
      console.error('❌ 缺少必需參數')
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
    console.log(`📌 標題: ${title}`)
    console.log(`📄 內容: ${message}`)

    // 如果配置了 OneSignal，發送真實通知
    if (ONESIGNAL_APP_ID && ONESIGNAL_REST_API_KEY) {
      console.log('🚀 使用 OneSignal 發送推送通知...')
      
      try {
        const onesignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
          },
          body: JSON.stringify({
            app_id: ONESIGNAL_APP_ID,
            include_external_user_ids: [userId],
            headings: { en: title, zh: title },
            contents: { en: message, zh: message },
            data: data || {},
            priority: 10,
            isIos: true,
            isAndroid: true,
          }),
        })

        const onesignalData = await onesignalResponse.json()
        console.log('✅ OneSignal 響應:', onesignalData)

        if (onesignalResponse.ok) {
          console.log('✅ 推送通知已通過 OneSignal 發送')
          return new Response(
            JSON.stringify({ 
              success: true, 
              message: '通知已通過 OneSignal 發送',
              onesignalId: onesignalData.body?.notification_id,
              data: {
                userId,
                title,
                message,
                type: type || 'general',
                timestamp: new Date().toISOString()
              }
            }),
            { 
              status: 200, 
              headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            }
          )
        } else {
          console.error('❌ OneSignal 返回錯誤:', onesignalData)
          throw new Error(`OneSignal error: ${onesignalData.errors?.join(', ')}`)
        }
      } catch (onesignalError) {
        console.error('❌ OneSignal 發送失敗:', onesignalError)
        throw onesignalError
      }
    } else {
      console.warn('⚠️ 未配置 OneSignal 憑證，只記錄日誌')
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: '通知已記錄（未配置推送服務）',
          data: {
            userId,
            title,
            message,
            type: type || 'general',
            timestamp: new Date().toISOString()
          }
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
  } catch (error) {
    console.error('❌ 錯誤:', error)
    console.error('錯誤堆棧:', error.stack)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message,
        stack: error.stack
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
