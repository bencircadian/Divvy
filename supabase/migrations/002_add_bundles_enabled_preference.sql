-- Add bundles_enabled preference to profiles table
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/njdkpymsjjlowpynfinr/sql

-- Add column to profiles table
-- NULL means user hasn't chosen yet (will be prompted)
-- TRUE means bundles are enabled
-- FALSE means bundles are disabled (tasks shown individually)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS bundles_enabled BOOLEAN DEFAULT NULL;

-- Add comment for documentation
COMMENT ON COLUMN profiles.bundles_enabled IS 'User preference for task bundles. NULL=not set (prompt user), TRUE=enabled, FALSE=disabled';
