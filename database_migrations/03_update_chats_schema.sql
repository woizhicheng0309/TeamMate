-- 更新 chats 表结构以支持群组聊天
-- 注意：请在 Supabase SQL Editor 中运行此脚本

-- 1. 添加新列（如果不存在）
ALTER TABLE chats ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'private';
ALTER TABLE chats ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE chats ADD COLUMN IF NOT EXISTS participants TEXT[] DEFAULT '{}';
ALTER TABLE chats ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE chats ADD COLUMN IF NOT EXISTS unread_count INTEGER DEFAULT 0;

-- 2. 如果是新数据库，删除旧的 user1_id 和 user2_id（如果需要）
-- 注意：只有在确认数据已迁移后才执行这些命令
-- ALTER TABLE chats DROP COLUMN IF EXISTS user1_id;
-- ALTER TABLE chats DROP COLUMN IF EXISTS user2_id;
-- ALTER TABLE chats DROP COLUMN IF EXISTS group_name;

-- 3. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_chats_activity_id ON chats(activity_id);
CREATE INDEX IF NOT EXISTS idx_chats_type ON chats(type);
CREATE INDEX IF NOT EXISTS idx_chats_participants ON chats USING GIN(participants);

-- 4. 如果有现有数据需要迁移，使用以下脚本
-- 迁移私聊数据
-- UPDATE chats 
-- SET 
--   type = 'private',
--   participants = ARRAY[user1_id, user2_id],
--   name = (SELECT name FROM users WHERE id = user2_id LIMIT 1)
-- WHERE activity_id IS NULL;

-- 迁移群组聊天数据（如果有）
-- UPDATE chats 
-- SET 
--   type = 'group',
--   name = group_name,
--   participants = (SELECT ARRAY_AGG(user_id) FROM participants WHERE activity_id = chats.activity_id)
-- WHERE activity_id IS NOT NULL;

-- 5. 添加 Row Level Security (RLS) 策略
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- 允许用户查看自己参与的聊天
CREATE POLICY "Users can view their own chats"
  ON chats FOR SELECT
  USING (auth.uid()::text = ANY(participants));

-- 允许用户创建聊天
CREATE POLICY "Users can create chats"
  ON chats FOR INSERT
  WITH CHECK (auth.uid()::text = ANY(participants));

-- 允许参与者更新聊天（如更新最后消息）
CREATE POLICY "Participants can update chats"
  ON chats FOR UPDATE
  USING (auth.uid()::text = ANY(participants));

-- 6. 确保 chat_messages 表有正确的结构
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'text';
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS sender_avatar TEXT;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- 创建消息索引
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
