#!/bin/bash
# Local Development Setup Script
# This script helps you get started with local development by setting up your .env file

set -e

echo "🚀 Setting up local development environment..."
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Your existing .env file remains unchanged."
        exit 0
    fi
fi

# Copy template to .env
if [ -f ".env.template" ]; then
    cp .env.template .env
    echo "✅ Created .env file from template"
else
    echo "❌ .env.template not found! Please make sure you're in the repository root."
    exit 1
fi

echo ""
echo "📝 Next steps:"
echo "1. Edit the .env file and fill in your actual Snowflake credentials:"
echo "   - SNOWFLAKE_ACCOUNT (format: account.region.cloud)"
echo "   - LIQUIBASE_PASSWORD (password for LIQUIBASE_USER)"
echo "   - DBT_PASSWORD (password for DBT_USER)"
echo ""
echo "2. Run the Snowflake setup script first:"
echo "   Execute scripts/snowflake_setup.sql in your Snowflake account"
echo ""
echo "3. Use the local wrapper scripts:"
echo "   ./scripts/liquibase-local.sh status"
echo "   ./scripts/dbt-local.sh compile"
echo ""
echo "🔒 Remember: Never commit your .env file to git!"
echo ""

# Make scripts executable
if [ -f "scripts/liquibase-local.sh" ]; then
    chmod +x scripts/liquibase-local.sh
fi
if [ -f "scripts/dbt-local.sh" ]; then
    chmod +x scripts/dbt-local.sh
fi

echo "✅ Setup complete! Edit your .env file to get started."