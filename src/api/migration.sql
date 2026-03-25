-- Database Migration Script for Todo Management App
-- This script adds Phase 1 and Phase 2 fields to the todos table
-- 
-- Usage:
-- sqlite3 todo.db < migration.sql
-- 
-- Or in Python:
-- import sqlite3
-- conn = sqlite3.connect('todo.db')
-- cursor = conn.cursor()
-- with open('migration.sql') as f:
--     cursor.executescript(f.read())
-- conn.commit()
-- conn.close()

-- Phase 1: AI-Readiness Fields
-- These fields support task analysis, prioritization, and categorization

ALTER TABLE todos ADD COLUMN estimated_hours INTEGER DEFAULT NULL;
-- Description: Estimated effort in hours
-- Example values: 2, 4, 8

ALTER TABLE todos ADD COLUMN complexity TEXT DEFAULT NULL;
-- Description: Task complexity level
-- Example values: 'simple', 'medium', 'complex'

ALTER TABLE todos ADD COLUMN project TEXT DEFAULT NULL;
-- Description: Project or epic name
-- Example values: 'Q1 Planning', 'Customer Portal', 'Backend API'

ALTER TABLE todos ADD COLUMN category TEXT DEFAULT NULL;
-- Description: Task category/type
-- Example values: 'feature', 'bug', 'refactor', 'documentation'


-- Phase 2: Execution Tracking Fields
-- These fields support actual effort tracking and dependency management

ALTER TABLE todos ADD COLUMN actual_hours INTEGER DEFAULT NULL;
-- Description: Actual time spent in hours
-- Example values: 2, 3, 5

ALTER TABLE todos ADD COLUMN dependencies TEXT DEFAULT NULL;
-- Description: JSON array of task dependencies (task IDs)
-- Example value: '["task-123", "task-456"]'

ALTER TABLE todos ADD COLUMN required_skills TEXT DEFAULT NULL;
-- Description: JSON array of required technical skills
-- Example value: '["React", "TypeScript", "Node.js"]'


-- Completion Tracking Fields
-- Support capturing what was actually accomplished

ALTER TABLE todos ADD COLUMN completed_at DATETIME DEFAULT NULL;
-- Description: Timestamp when task was marked complete
-- Example value: '2024-03-24 15:30:00+00:00'

ALTER TABLE todos ADD COLUMN completed_content TEXT DEFAULT NULL;
-- Description: Final content/notes captured at completion
-- Example value: 'Deployed v2.1.0 with improved error handling'


-- Create indexes for commonly queried fields
CREATE INDEX IF NOT EXISTS idx_owner_project ON todos(owner_id, project);
-- For filtering todos by project

CREATE INDEX IF NOT EXISTS idx_owner_category ON todos(owner_id, category);
-- For filtering todos by category

-- View the schema
-- PRAGMA table_info(todos);
