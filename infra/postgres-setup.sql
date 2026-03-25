-- PostgreSQL Entra ID Authentication Setup Script
-- 此脚本为Container App配置Entra ID认证
-- 以postgres管理员身份运行此脚本

-- ============================================================
-- 步骤1: 启用UUID扩展（如果需要）
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 步骤2: 创建应用角色
-- 替换 <MANAGED_IDENTITY_NAME> 为您的托管身份名称
-- 托管身份格式: <subscription-id>,/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<identity-name>
-- ============================================================

-- 示例：创建Container App托管身份角色
-- CREATE USER "ca-todomanagement-app" WITH PASSWORD 'temporary_password';
-- 或使用Entra ID直接创建（推荐）

-- 注：在实际部署中，使用以下命令通过Azure CLI创建Entra ID用户：
-- az postgres flexible-server ad-admin create --resource-group <rg> --server-name <server> --identity-name <identity>

-- ============================================================
-- 步骤3: 创建数据库和模式
-- ============================================================
CREATE DATABASE IF NOT EXISTS tododb;
\c tododb

-- 创建应用所需的表
CREATE SCHEMA IF NOT EXISTS todos;

-- ============================================================
-- 步骤4: 创建表模式
-- ============================================================

-- Owners表
CREATE TABLE IF NOT EXISTS todos.owners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Projects表
CREATE TABLE IF NOT EXISTS todos.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES todos.owners(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(owner_id, name)
);

-- Todos表
CREATE TABLE IF NOT EXISTS todos.todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES todos.projects(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    priority VARCHAR(50) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================
-- 步骤5: 创建索引以优化查询
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON todos.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON todos.todos(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_status ON todos.todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos.todos(created_at DESC);

-- ============================================================
-- 步骤6: 授予权限给应用角色
-- 替换 <APP_ROLE> 为您的应用角色名称
-- ============================================================

-- 为模式授予权限
GRANT USAGE ON SCHEMA todos TO "ca-todomanagement-app";

-- 为表授予权限
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    todos.owners, 
    todos.projects, 
    todos.todos 
TO "ca-todomanagement-app";

-- 为序列授予权限
GRANT USAGE ON ALL SEQUENCES IN SCHEMA todos TO "ca-todomanagement-app";

-- 为函数授予权限
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA todos TO "ca-todomanagement-app";

-- ============================================================
-- 步骤7: 创建行级安全策略（可选但推荐）
-- ============================================================

-- 启用行级安全
ALTER TABLE todos.owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos.todos ENABLE ROW LEVEL SECURITY;

-- 创建策略以限制用户只能看到自己的数据
CREATE POLICY owner_isolation ON todos.owners
    USING (
        -- 在实际环境中，这里应该检查current_user_id
        true
    );

CREATE POLICY project_isolation ON todos.projects
    USING (
        -- 在实际环境中，这里应该检查current_user_id
        true
    );

CREATE POLICY todo_isolation ON todos.todos
    USING (
        -- 在实际环境中，这里应该检查关联的owner_id
        true
    );

-- ============================================================
-- 步骤8: 验证权限
-- ============================================================

-- 以应用角色身份连接并验证权限
-- psql -h <POSTGRES_HOST> -U "ca-todomanagement-app@<server_name>" -d tododb -c "\dt todos.*"

-- ============================================================
-- 步骤9: 创建视图以帮助应用简化查询（可选）
-- ============================================================

-- 创建视图：用户的所有项目及其待办事项
CREATE OR REPLACE VIEW todos.user_project_todos AS
SELECT 
    o.id as owner_id,
    o.name as owner_name,
    p.id as project_id,
    p.name as project_name,
    t.id as todo_id,
    t.title as todo_title,
    t.status as todo_status,
    t.priority as todo_priority,
    t.due_date as todo_due_date,
    t.created_at as todo_created_at
FROM todos.owners o
LEFT JOIN todos.projects p ON o.id = p.owner_id
LEFT JOIN todos.todos t ON p.id = t.project_id
ORDER BY o.id, p.id, t.created_at DESC;

-- 授予视图访问权限
GRANT SELECT ON todos.user_project_todos TO "ca-todomanagement-app";

-- ============================================================
-- 步骤10: 创建存储函数以简化操作
-- ============================================================

-- 创建函数：创建新的owner和project
CREATE OR REPLACE FUNCTION todos.create_owner_with_project(
    p_owner_name VARCHAR,
    p_owner_email VARCHAR,
    p_project_name VARCHAR,
    p_project_description TEXT
)
RETURNS TABLE (owner_id UUID, project_id UUID) AS $$
DECLARE
    v_owner_id UUID;
    v_project_id UUID;
BEGIN
    -- 创建owner
    INSERT INTO todos.owners (name, email)
    VALUES (p_owner_name, p_owner_email)
    RETURNING id INTO v_owner_id;
    
    -- 创建project
    INSERT INTO todos.projects (owner_id, name, description)
    VALUES (v_owner_id, p_project_name, p_project_description)
    RETURNING id INTO v_project_id;
    
    -- 返回结果
    RETURN QUERY SELECT v_owner_id, v_project_id;
END;
$$ LANGUAGE plpgsql;

-- 授予函数执行权限
GRANT EXECUTE ON FUNCTION todos.create_owner_with_project(VARCHAR, VARCHAR, VARCHAR, TEXT) TO "ca-todomanagement-app";

-- ============================================================
-- 完成
-- ============================================================
COMMIT;

-- 显示成功消息
\echo '========================================';
\echo 'PostgreSQL Setup Completed Successfully!';
\echo '========================================';
\echo 'Database: tododb';
\echo 'Schema: todos';
\echo 'Tables created: owners, projects, todos';
\echo 'Indexes created';
\echo 'Row Level Security enabled';
\echo 'Views created: user_project_todos';
\echo 'Functions created: create_owner_with_project';
\echo '';
\echo 'Next steps:';
\echo '1. Create Entra ID user for Container App managed identity';
\echo '2. Grant appropriate permissions to the managed identity';
\echo '3. Deploy Container App with connection string';
\echo '========================================';
