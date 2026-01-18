-- Security Fixes for Supabase Linter Warnings
-- Run this migration in Supabase SQL Editor to address security warnings
--
-- IMPORTANT: Test thoroughly after running as notification insertion may be affected

-- ============================================
-- 1. Fix Function Search Path Mutable Warnings
-- ============================================
-- Setting search_path prevents potential schema injection attacks

ALTER FUNCTION public.check_invite_rate_limit(text) SET search_path = public;
ALTER FUNCTION public.cleanup_old_invite_attempts() SET search_path = public;
ALTER FUNCTION public.get_weekly_task_counts(uuid) SET search_path = public;
ALTER FUNCTION public.get_workload_distribution(uuid) SET search_path = public;

-- ============================================
-- 2. Fix RLS Policy for Notifications INSERT
-- ============================================
-- The current "System can insert notifications" policy uses WITH CHECK (true)
-- which allows any authenticated user to insert notifications to any user.
--
-- This fix restricts notification creation to:
-- - Users in the same household as the notification recipient
-- - Service role (for triggers/backend - bypasses RLS anyway)

-- First, drop the overly permissive policy
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;

-- Create a restricted policy: users can only insert notifications for
-- users in their same household
CREATE POLICY "Users can insert notifications for household members"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  -- Inserter must share a household with the notification recipient
  EXISTS (
    SELECT 1
    FROM public.household_members inserter_hm
    JOIN public.household_members recipient_hm
      ON inserter_hm.household_id = recipient_hm.household_id
    WHERE inserter_hm.user_id = auth.uid()
      AND recipient_hm.user_id = notifications.user_id
  )
);

-- Note: service_role bypasses RLS entirely, so no separate policy needed for it

-- ============================================
-- 3. Leaked Password Protection
-- ============================================
-- This CANNOT be set via SQL migration.
--
-- To enable, go to Supabase Dashboard:
-- 1. Navigate to Authentication > Settings
-- 2. Find "Password Protection" section
-- 3. Enable "Check passwords against HaveIBeenPwned database"
--
-- This adds an extra layer of security by preventing users from
-- using passwords that have been exposed in known data breaches.

-- ============================================
-- Verification Queries
-- ============================================
-- Run these after the migration to verify changes:

-- 1. Verify function search_path settings:
SELECT
  proname as function_name,
  proconfig as config
FROM pg_proc
WHERE proname IN (
  'check_invite_rate_limit',
  'cleanup_old_invite_attempts',
  'get_weekly_task_counts',
  'get_workload_distribution'
);

-- 2. Verify RLS policies on notifications table:
SELECT
  policyname,
  cmd,
  roles,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'notifications';

-- ============================================
-- Rollback Script (if needed)
-- ============================================
-- If notifications stop working, run this to revert:
--
-- DROP POLICY IF EXISTS "Users can insert notifications for household members" ON public.notifications;
-- CREATE POLICY "System can insert notifications" ON public.notifications
--   FOR INSERT WITH CHECK (true);
