#!/bin/bash
# Complete Snowflake Reset Workflow
# This script performs a full database reset and rebuild process

set -e

echo "🔄 Starting complete Snowflake database reset workflow..."
echo ""

# Step 1: Reset the database clone
echo "=== Step 1: Reset Development Database ==="
./scripts/reset-dev-database.sh

echo ""
echo "=== Step 2: Rebuild Analytics Models ==="

# Step 2: Rebuild dbt models in the fresh database
echo "🔧 Running dbt on fresh database..."
./scripts/dbt-local.sh run

echo ""
echo "=== Step 3: Validate Everything Works ==="

# Step 3: Run tests to validate everything works
echo "🧪 Running dbt tests..."
./scripts/dbt-local.sh test

# Step 4: Show status
echo ""
echo "=== Reset Complete! ==="
echo "✅ Database cloned from master"
echo "✅ dbt models rebuilt"  
echo "✅ All tests passing"
echo ""
echo "🎯 Your development environment is ready!"
echo ""

# Optional: Show some useful commands
echo "💡 Useful commands:"
echo "   ./scripts/liquibase-local.sh status    # Check schema deployment status"
echo "   ./scripts/dbt-local.sh run             # Rebuild analytics models"
echo "   ./scripts/dbt-local.sh test            # Run data quality tests"
echo "   ./scripts/reset-dev-database.sh        # Quick DB reset (no dbt rebuild)"
echo ""