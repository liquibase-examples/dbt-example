#!/bin/bash
# Liquibase Local Development Wrapper
# This script loads .env file and runs Liquibase commands with proper environment variables

set -e

# Function to load .env file
load_env() {
    if [ -f ".env" ]; then
        echo "🔧 Loading environment variables from .env file..."
        # Load and export all variables from .env
        export $(grep -v '^#' .env | xargs)
    else
        echo "⚠️  No .env file found. Please run ./scripts/setup-local.sh first"
        echo "   or manually create .env file from .env.template"
        exit 1
    fi
}

# Function to check required environment variables
check_env() {
    local missing_vars=()
    
    if [ -z "${SNOWFLAKE_ACCOUNT:-}" ]; then
        missing_vars+=("SNOWFLAKE_ACCOUNT")
    fi
    
    if [ -z "${LIQUIBASE_PASSWORD:-}" ]; then
        missing_vars+=("LIQUIBASE_PASSWORD")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "❌ Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "   - $var"
        done
        echo ""
        echo "Please update your .env file with the missing values."
        exit 1
    fi
}

# Show usage if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <liquibase-command> [options]"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 update"
    echo "  $0 flow --flow-file=liquibase/flowfiles/deploy.flowfile.yaml"
    echo "  $0 rollback --tag=v1.0"
    echo ""
    echo "This wrapper loads your .env file and runs Liquibase with the correct environment variables."
    exit 0
fi

# Load environment variables
load_env

# Check required variables
check_env

# Set default properties file if not specified
PROPS_FILE="liquibase/properties/liquibase.dev.properties"
if [[ ! " $@ " =~ " --defaults-file=" ]] && [[ ! " $@ " =~ " --defaultsFile=" ]]; then
    echo "🔧 Using default properties file: $PROPS_FILE"
    EXTRA_ARGS="--defaults-file=$PROPS_FILE"
else
    EXTRA_ARGS=""
fi

# Set default database if not specified
DB_NAME="${SNOWFLAKE_DATABASE:-ONLINE_STORE_DEV}"
WAREHOUSE_NAME="${SNOWFLAKE_WAREHOUSE:-COMPUTE_WH}"

# Set Liquibase-specific environment variables with dynamic database
export LIQUIBASE_COMMAND_URL="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?db=${DB_NAME}&schema=PUBLIC&warehouse=${WAREHOUSE_NAME}"
export LIQUIBASE_COMMAND_USERNAME="LIQUIBASE_USER"
export LIQUIBASE_COMMAND_PASSWORD="${LIQUIBASE_PASSWORD}"

# Run Liquibase with all arguments
echo "🚀 Running: liquibase $@ $EXTRA_ARGS"
echo ""
exec liquibase "$@" $EXTRA_ARGS