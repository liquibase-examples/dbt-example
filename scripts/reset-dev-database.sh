#!/bin/bash
# Quick Dev Database Reset Script
# Drops ONLINE_STORE_DEV and recreates it from ONLINE_STORE_MASTER clone

set -e

echo "🔄 Resetting development database..."

# Load environment variables to get Snowflake connection details
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ .env file not found. Please run ./scripts/setup-local.sh first"
    exit 1
fi

# Check required variables
if [ -z "${SNOWFLAKE_ACCOUNT:-}" ] || [ -z "${DATABASE_ADMIN_PASSWORD:-}" ]; then
    echo "❌ Missing required environment variables"
    echo "   Please ensure SNOWFLAKE_ACCOUNT and DATABASE_ADMIN_PASSWORD are set in .env"
    exit 1
fi

echo "📊 Connecting to Snowflake account: $SNOWFLAKE_ACCOUNT"

# Create SQL commands for the reset
RESET_SQL="
-- Drop the existing dev database (if it exists)
-- Note: DATABASE_ADMIN_ROLE must own this database
DROP DATABASE IF EXISTS ONLINE_STORE_DEV;

-- Create fresh dev database from ONLINE_STORE_DB (the master)
-- DATABASE_ADMIN_ROLE will automatically own this new database
CREATE DATABASE ONLINE_STORE_DEV 
    CLONE ONLINE_STORE_DB
    COMMENT = 'Development database - freshly cloned from master';

-- Grant permissions to both roles on the new dev database
GRANT USAGE ON DATABASE ONLINE_STORE_DEV TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON DATABASE ONLINE_STORE_DEV TO ROLE DBT_ROLE;

-- Grant schema permissions
GRANT ALL ON SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE DBT_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE DBT_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE DBT_ROLE;

GRANT ALL ON SCHEMA ONLINE_STORE_DEV.DBT TO ROLE DBT_ROLE;
GRANT USAGE ON SCHEMA ONLINE_STORE_DEV.DBT TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA ONLINE_STORE_DEV.DBT TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA ONLINE_STORE_DEV.DBT TO ROLE LIQUIBASE_ROLE;

-- Grant future object permissions
GRANT ALL ON FUTURE TABLES IN SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT ALL ON FUTURE VIEWS IN SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE DBT_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA ONLINE_STORE_DEV.PUBLIC TO ROLE DBT_ROLE;

GRANT ALL ON FUTURE TABLES IN SCHEMA ONLINE_STORE_DEV.DBT TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE VIEWS IN SCHEMA ONLINE_STORE_DEV.DBT TO ROLE DBT_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ONLINE_STORE_DEV.DBT TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA ONLINE_STORE_DEV.DBT TO ROLE LIQUIBASE_ROLE;

-- Show result
SELECT 'Database reset completed successfully' AS status;
SHOW DATABASES LIKE '%ONLINE_STORE%';
"

echo "🗑️  Dropping existing ONLINE_STORE_DEV..."
echo "📋 Cloning fresh copy from ONLINE_STORE_DB (master)..."

# Execute the reset using snow CLI
if command -v snow >/dev/null 2>&1; then
    echo "$RESET_SQL" | snow sql --temporary-connection \
        --account "$SNOWFLAKE_ACCOUNT" \
        --user DATABASE_ADMIN_USER \
        --password "$DATABASE_ADMIN_PASSWORD" \
        --role DATABASE_ADMIN_ROLE \
        --warehouse COMPUTE_WH \
        --silent
else
    echo "⚠️  Snowflake CLI not found. Please run the following SQL manually in Snowflake:"
    echo ""
    echo "$RESET_SQL"
    echo ""
    echo "Or install snow CLI with: pipx install snowflake-cli-labs"
    exit 1
fi

echo ""
echo "✅ Development database reset complete!"
echo "📊 ONLINE_STORE_DEV is now a fresh clone of ONLINE_STORE_DB"
echo ""
echo "💡 Next steps:"
echo "   1. Update your .env file: SNOWFLAKE_DATABASE=ONLINE_STORE_DEV"
echo "   2. Run: ./scripts/dbt-local.sh run    # Rebuild analytics models"
echo "   3. Run: ./scripts/dbt-local.sh test   # Verify everything works"