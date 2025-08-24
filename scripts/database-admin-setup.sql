-- =====================================================
-- Database Admin Setup Script for Dev Database Reset
-- Requires ACCOUNTADMIN role to execute
-- =====================================================

-- NOTE: This script must be run by a user with ACCOUNTADMIN role
-- The CREATE DATABASE privilege can only be granted by ACCOUNTADMIN

USE ROLE ACCOUNTADMIN;

-- Create database admin user for dev database reset operations
CREATE USER IF NOT EXISTS DATABASE_ADMIN_USER 
    PASSWORD = 'DbAdmin2024#Reset!' 
    DEFAULT_ROLE = 'DATABASE_ADMIN_ROLE'
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT = 'Admin user for development database reset operations (drop/clone)';

-- Create role specifically for database management operations
CREATE ROLE IF NOT EXISTS DATABASE_ADMIN_ROLE 
    COMMENT = 'Role with privileges to drop and create databases for dev environment resets';

-- Grant the CREATE DATABASE privilege (only ACCOUNTADMIN can grant this)
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DATABASE_ADMIN_ROLE;

-- Grant MANAGE GRANTS privilege so the role can grant permissions to other roles
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE DATABASE_ADMIN_ROLE;

-- Grant usage on the warehouse for operations
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DATABASE_ADMIN_ROLE;

-- Grant usage on the master database for cloning operations
GRANT USAGE ON DATABASE ONLINE_STORE_DB TO ROLE DATABASE_ADMIN_ROLE;

-- Grant usage on schemas for reading data during clone operations
GRANT USAGE ON SCHEMA ONLINE_STORE_DB.PUBLIC TO ROLE DATABASE_ADMIN_ROLE;
GRANT USAGE ON SCHEMA ONLINE_STORE_DB.DBT TO ROLE DATABASE_ADMIN_ROLE;

-- Grant SELECT permissions on master database for cloning
GRANT SELECT ON ALL TABLES IN SCHEMA ONLINE_STORE_DB.PUBLIC TO ROLE DATABASE_ADMIN_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA ONLINE_STORE_DB.PUBLIC TO ROLE DATABASE_ADMIN_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA ONLINE_STORE_DB.DBT TO ROLE DATABASE_ADMIN_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA ONLINE_STORE_DB.DBT TO ROLE DATABASE_ADMIN_ROLE;

-- Grant SELECT on future objects in master database
GRANT SELECT ON FUTURE TABLES IN SCHEMA ONLINE_STORE_DB.PUBLIC TO ROLE DATABASE_ADMIN_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA ONLINE_STORE_DB.PUBLIC TO ROLE DATABASE_ADMIN_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ONLINE_STORE_DB.DBT TO ROLE DATABASE_ADMIN_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA ONLINE_STORE_DB.DBT TO ROLE DATABASE_ADMIN_ROLE;

-- Assign the role to the user
GRANT ROLE DATABASE_ADMIN_ROLE TO USER DATABASE_ADMIN_USER;

-- Grant ownership of ONLINE_STORE_DEV database to enable drop operations
-- Note: This will be executed after the database is first created
-- For existing databases, run: GRANT OWNERSHIP ON DATABASE ONLINE_STORE_DEV TO ROLE DATABASE_ADMIN_ROLE;

-- Show results
SELECT 'Database admin setup completed successfully' AS status;
SHOW USERS LIKE 'DATABASE_ADMIN_USER';
SHOW GRANTS TO ROLE DATABASE_ADMIN_ROLE;

-- =====================================================
-- IMPORTANT SETUP INSTRUCTIONS:
-- =====================================================
-- 1. Run this script as ACCOUNTADMIN role
-- 2. If ONLINE_STORE_DEV already exists, transfer ownership by running:
--    GRANT OWNERSHIP ON DATABASE ONLINE_STORE_DEV TO ROLE DATABASE_ADMIN_ROLE REVOKE CURRENT GRANTS;
--    Note: This will revoke all existing grants. Re-run the reset script to restore permissions.
-- 3. Update your .env file with: DATABASE_ADMIN_PASSWORD=DbAdmin2024#Reset!
-- 4. Add DATABASE_ADMIN_PASSWORD to GitHub repository secrets
-- =====================================================