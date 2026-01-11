-- Performance indexes for Divvy app
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/njdkpymsjjlowpynfinr/sql

-- CRITICAL: Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_tasks_household_id ON tasks(household_id);
CREATE INDEX IF NOT EXISTS idx_tasks_household_status ON tasks(household_id, status);
CREATE INDEX IF NOT EXISTS idx_household_members_user_id ON household_members(user_id);
CREATE INDEX IF NOT EXISTS idx_household_members_household_id ON household_members(household_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_households_invite_code ON households(invite_code);

-- HIGH IMPACT: Filtering and sorting indexes
CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks(completed_at);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_task_notes_task_id ON task_notes(task_id);
CREATE INDEX IF NOT EXISTS idx_task_history_task_id ON task_history(task_id);
CREATE INDEX IF NOT EXISTS idx_user_streaks_household_id ON user_streaks(household_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);

-- Rate limiting table for invite code attempts
CREATE TABLE IF NOT EXISTS invite_code_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address TEXT NOT NULL,
    attempted_code TEXT NOT NULL,
    attempted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invite_attempts_ip ON invite_code_attempts(ip_address, attempted_at);

-- Function to check rate limit (max 10 attempts per minute per IP)
CREATE OR REPLACE FUNCTION check_invite_rate_limit(client_ip TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    attempt_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO attempt_count
    FROM invite_code_attempts
    WHERE ip_address = client_ip
    AND attempted_at > NOW() - INTERVAL '1 minute';

    RETURN attempt_count < 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean up old rate limit entries (run periodically)
CREATE OR REPLACE FUNCTION cleanup_old_invite_attempts()
RETURNS void AS $$
BEGIN
    DELETE FROM invite_code_attempts
    WHERE attempted_at < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Dashboard aggregation functions (avoid client-side counting)
-- ============================================================

-- Get task completion counts per user for a household (this week)
CREATE OR REPLACE FUNCTION get_weekly_task_counts(p_household_id UUID)
RETURNS TABLE(user_id UUID, task_count BIGINT) AS $$
DECLARE
    week_start DATE;
BEGIN
    -- Calculate start of current week (Monday)
    week_start := date_trunc('week', CURRENT_DATE)::DATE;

    RETURN QUERY
    SELECT
        t.completed_by::UUID as user_id,
        COUNT(*)::BIGINT as task_count
    FROM tasks t
    WHERE t.household_id = p_household_id
      AND t.status = 'completed'
      AND t.completed_at >= week_start
      AND t.completed_by IS NOT NULL
    GROUP BY t.completed_by;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get workload distribution (pending tasks per assignee)
CREATE OR REPLACE FUNCTION get_workload_distribution(p_household_id UUID)
RETURNS TABLE(user_id UUID, task_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.assigned_to::UUID as user_id,
        COUNT(*)::BIGINT as task_count
    FROM tasks t
    WHERE t.household_id = p_household_id
      AND t.status = 'pending'
      AND t.assigned_to IS NOT NULL
    GROUP BY t.assigned_to;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
