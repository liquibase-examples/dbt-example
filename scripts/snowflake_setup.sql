-- =====================================================
-- Snowflake Setup Script for Liquibase + dbt Integration
-- Based on solution-guide.md architectural principles
-- =====================================================

-- Database setup
CREATE DATABASE IF NOT EXISTS ONLINE_STORE_DB;
USE DATABASE ONLINE_STORE_DB;

-- Schema creation following separation of duties principle
CREATE SCHEMA IF NOT EXISTS PUBLIC;    -- For Liquibase-managed objects (source tables, static objects)
CREATE SCHEMA IF NOT EXISTS DBT;       -- For dbt-managed transformations (views, models)

-- Create service accounts with separate permissions
CREATE USER IF NOT EXISTS LIQUIBASE_USER 
    PASSWORD = 'ChangeMe123!' 
    DEFAULT_ROLE = 'LIQUIBASE_ROLE'
    MUST_CHANGE_PASSWORD = TRUE
    COMMENT = 'Service account for Liquibase schema management';

CREATE USER IF NOT EXISTS DBT_USER 
    PASSWORD = 'ChangeMe456!' 
    DEFAULT_ROLE = 'DBT_ROLE'
    MUST_CHANGE_PASSWORD = TRUE
    COMMENT = 'Service account for dbt transformations';

-- Create roles with clear separation
CREATE ROLE IF NOT EXISTS LIQUIBASE_ROLE COMMENT = 'Role for managing schema DDL and source tables';
CREATE ROLE IF NOT EXISTS DBT_ROLE COMMENT = 'Role for managing transformation models and views';

-- Grant database permissions
GRANT USAGE ON DATABASE ONLINE_STORE_DB TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON DATABASE ONLINE_STORE_DB TO ROLE DBT_ROLE;

-- Schema permissions following the permission model from solution guide
-- Liquibase has full control of PUBLIC schema
GRANT ALL ON SCHEMA PUBLIC TO ROLE LIQUIBASE_ROLE;
-- dbt can only read from PUBLIC schema (source tables)
GRANT USAGE ON SCHEMA PUBLIC TO ROLE DBT_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO ROLE DBT_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA PUBLIC TO ROLE DBT_ROLE;

-- dbt has full control of DBT schema
GRANT ALL ON SCHEMA DBT TO ROLE DBT_ROLE;
-- Liquibase cannot modify DBT schema (prevents accidental cross-management)
GRANT USAGE ON SCHEMA DBT TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA DBT TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA DBT TO ROLE LIQUIBASE_ROLE;

-- Grant future object permissions to maintain separation
-- Liquibase manages all future objects in PUBLIC
GRANT ALL ON FUTURE TABLES IN SCHEMA PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT ALL ON FUTURE VIEWS IN SCHEMA PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PUBLIC TO ROLE DBT_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA PUBLIC TO ROLE DBT_ROLE;

-- dbt manages all future objects in DBT schema
GRANT ALL ON FUTURE TABLES IN SCHEMA DBT TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE VIEWS IN SCHEMA DBT TO ROLE DBT_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DBT TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA DBT TO ROLE LIQUIBASE_ROLE;

-- Assign roles to users
GRANT ROLE LIQUIBASE_ROLE TO USER LIQUIBASE_USER;
GRANT ROLE DBT_ROLE TO USER DBT_USER;

-- Create warehouse with appropriate size
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Shared compute warehouse for Liquibase and dbt operations';

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DBT_ROLE;

-- Create audit table for tracking deployments (managed by Liquibase)
CREATE TABLE IF NOT EXISTS PUBLIC.DEPLOYMENT_AUDIT (
    deployment_id NUMBER AUTOINCREMENT,
    deployment_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    deployment_type VARCHAR(50), -- 'LIQUIBASE' or 'DBT'
    deployment_user VARCHAR(100),
    deployment_status VARCHAR(20),
    deployment_details VARIANT,
    PRIMARY KEY (deployment_id)
);

-- Grant dbt permission to log its deployments
GRANT INSERT ON TABLE PUBLIC.DEPLOYMENT_AUDIT TO ROLE DBT_ROLE;