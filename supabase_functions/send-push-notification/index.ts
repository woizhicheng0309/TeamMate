// Supabase Edge Function - 發送推送通知
// 部署指令: supabase functions deploy send-push-notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

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

    // TODO: 這裡可以集成 OneSignal, Firebase 或其他推送服務
    // 目前只記錄日誌
    console.log('✅ 通知已準備發送（暫不發送到實際服務）')

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: '通知已記錄',
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
