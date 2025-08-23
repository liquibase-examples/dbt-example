#!/bin/bash
# dbt Local Development Wrapper
# This script loads .env file and runs dbt commands with proper environment variables

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
    
    if [ -z "${DBT_PASSWORD:-}" ]; then
        missing_vars+=("DBT_PASSWORD")
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
    echo "Usage: $0 <dbt-command> [options]"
    echo ""
    echo "Examples:"
    echo "  $0 compile"
    echo "  $0 run"
    echo "  $0 test"
    echo "  $0 run --target dev"
    echo "  $0 docs generate"
    echo ""
    echo "This wrapper loads your .env file and runs dbt with the correct environment variables."
    echo "All commands are executed from the dbt/ directory."
    exit 0
fi

# Load environment variables
load_env

# Check required variables
check_env

# Change to dbt directory
if [ ! -d "dbt" ]; then
    echo "❌ dbt directory not found. Please run this script from the repository root."
    exit 1
fi

cd dbt

# Set default target if not specified
if [[ ! " $@ " =~ " --target " ]] && [[ ! " $@ " =~ " -t " ]]; then
    echo "🔧 Using default target: dev"
    EXTRA_ARGS="--target dev"
else
    EXTRA_ARGS=""
fi

# Run dbt with all arguments
echo "🚀 Running: dbt $@ $EXTRA_ARGS"
echo "📁 Working directory: $(pwd)"
echo ""
exec dbt "$@" $EXTRA_ARGS