-- 创建加入申请表
CREATE TABLE IF NOT EXISTS public.join_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL,
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT join_requests_pkey PRIMARY KEY (id),
  CONSTRAINT join_requests_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activities(id) ON DELETE CASCADE,
  CONSTRAINT join_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT join_requests_unique UNIQUE (activity_id, user_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_join_requests_activity_id ON join_requests(activity_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_user_id ON join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON join_requests(status);

-- 启用 RLS
ALTER TABLE join_requests ENABLE ROW LEVEL SECURITY;

-- 删除已存在的策略（如果存在）
DROP POLICY IF EXISTS "Users can view their own requests" ON join_requests;
DROP POLICY IF EXISTS "Creators can view activity requests" ON join_requests;
DROP POLICY IF EXISTS "Users can create join requests" ON join_requests;
DROP POLICY IF EXISTS "Creators can update request status" ON join_requests;

-- 允许用户查看自己的申请
CREATE POLICY "Users can view their own requests"
  ON join_requests FOR SELECT
  USING (auth.uid()::text = user_id::text);

-- 允许活动创建者查看自己活动的申请
CREATE POLICY "Creators can view activity requests"
  ON join_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = join_requests.activity_id
      AND activities.creator_id::text = auth.uid()::text
    )
  );

-- 允许用户创建申请
CREATE POLICY "Users can create join requests"
  ON join_requests FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

-- 允许活动创建者更新申请状态
CREATE POLICY "Creators can update request status"
  ON join_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = join_requests.activity_id
      AND activities.creator_id::text = auth.uid()::text
    )
  );
