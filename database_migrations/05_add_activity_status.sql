-- 添加或更新活动状态字段
-- 如果 status 列不存在，则添加它
ALTER TABLE public.activities 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'open';

-- 移除旧的约束（如果存在）
ALTER TABLE public.activities DROP CONSTRAINT IF EXISTS activities_status_check;

-- 添加新的约束允许更多状态值
ALTER TABLE public.activities 
ADD CONSTRAINT activities_status_check CHECK (status IN ('open', 'full', 'completed', 'cancelled', 'active', 'ended'));

-- 创建状态索引
CREATE INDEX IF NOT EXISTS idx_activities_status ON activities(status);

-- 保留现有的状态值，不做修改
-- UPDATE public.activities SET status = 'open' WHERE status IS NULL;

