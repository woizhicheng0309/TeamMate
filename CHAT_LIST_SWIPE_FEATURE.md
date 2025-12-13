# 聊天列表左滑功能说明

## 功能说明

用户现在可以在聊天列表中使用左滑手势对聊天进行操作：

### 左滑操作
1. **从左向右滑动**：置顶/取消置顶聊天（橙色背景）
2. **从右向左滑动**：删除聊天（红色背景）

## 数据库更新

需要在 Supabase 数据库中添加 `is_pinned` 列：

### 方法 1：通过 Supabase Dashboard
1. 打开 [Supabase Dashboard](https://supabase.com/dashboard)
2. 进入 SQL Editor
3. 复制并执行以下 SQL：

```sql
-- 添加 is_pinned 列到 chats 表
ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false;

-- 创建索引以加快查询
CREATE INDEX IF NOT EXISTS idx_chats_is_pinned ON public.chats(is_pinned DESC);
```

### 方法 2：使用迁移文件
```bash
cd /Users/woizhicheng/Desktop/TeamMate/teammate_app

# 应用迁移
supabase db push
```

## 使用说明

1. **热重载应用**（按 `r`）
2. 打开聊天列表
3. 在任何聊天项上向左滑动
4. 选择操作：
   - 置顶：让重要的聊天始终显示在列表顶部
   - 删除：永久删除聊天记录

## 特性

✅ 置顶的聊天显示在列表顶部
✅ 未置顶的聊天显示在下方
✅ 删除操作立即生效
✅ 提示信息反馈操作结果

## 注意事项

- 删除聊天是不可逆的操作
- 置顶状态仅针对当前用户
- 置顶的聊天依然会接收新消息
