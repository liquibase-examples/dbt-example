# Liquibase + dbt Integration Pattern

This repository demonstrates best practices for integrating Liquibase database schema management with dbt analytics transformations in Snowflake. The pattern implements a clear separation of concerns where Liquibase manages structural database changes while dbt handles data transformations and analytics models.

**✨ Now with GitHub Pages deployment!** All Liquibase deployment reports are automatically deployed to GitHub Pages for instant browser access without downloads.

## Architecture Overview

### Separation of Duties
- **Liquibase**: Manages database schema objects (tables, indexes, constraints) in the `PUBLIC` schema
- **dbt**: Creates analytics views and tables in the `DBT` schema
- **Service Accounts**: Separate users with appropriate permissions for each tool

### Database Organization
```
ONLINE_STORE_DB
├── PUBLIC (Liquibase-managed)
│   ├── CUSTOMERS
│   ├── PRODUCTS  
│   ├── ORDERS
│   └── ORDER_ITEMS
└── DBT (dbt-managed)
    ├── CUSTOMER_ORDER_SUMMARY
    └── PRODUCT_SALES_ANALYSIS
```

## Quick Start

### Prerequisites
- Snowflake account with appropriate permissions
- Liquibase Pro license
- dbt CLI installed locally
- GitHub repository with Actions enabled

### Local Development Setup

1. **Run Snowflake Setup**
   ```sql
   -- Execute scripts/snowflake_setup.sql in your Snowflake account
   -- This creates the required databases, users, roles, and permissions
   
   -- Then execute scripts/database-admin-setup.sql as ACCOUNTADMIN
   -- This creates the database admin user for dev database reset operations
   ```

2. **Setup Local Environment**
   ```bash
   # Run the setup script to create your .env file
   ./scripts/setup-local.sh
   
   # Edit .env file with your actual Snowflake credentials
   # SNOWFLAKE_ACCOUNT=your-account.region.cloud
   # LIQUIBASE_PASSWORD=your_liquibase_password
   # DBT_PASSWORD=your_dbt_password
   # DATABASE_ADMIN_PASSWORD=your_database_admin_password
   ```

3. **Deploy Schema Changes**
   ```bash
   # Deploy database structure with Liquibase
   ./scripts/liquibase-local.sh flow --flow-file=liquibase/flowfiles/deploy.flowfile.yaml
   
   # Run dbt transformations
   ./scripts/dbt-local.sh run
   
   # Test your setup
   ./scripts/liquibase-local.sh status
   ./scripts/dbt-local.sh test
   ```

### CI/CD Setup (GitHub Actions)

For automated deployments, configure these GitHub Secrets:
- `SNOWFLAKE_ACCOUNT` - your account identifier
- `LIQUIBASE_DEV_PASSWORD` / `LIQUIBASE_PROD_PASSWORD`
- `DBT_DEV_PASSWORD` / `DBT_PROD_PASSWORD`
- `DATABASE_ADMIN_PASSWORD` - for dev database reset operations

## Directory Structure

```
├── .github/workflows/          # CI/CD automation
│   ├── pr-validation.yml       # PR validation checks
│   ├── deploy-dev.yml          # Auto-deploy to dev
│   ├── release-prod.yml        # Production releases
│   └── rollback.yml            # Emergency rollback
├── liquibase/
│   ├── changelogs/             # Database schema changes
│   ├── flowfiles/              # Liquibase Flow automation
│   └── properties/             # Environment configurations
├── dbt/
│   ├── models/                 # Analytics transformations
│   ├── dbt_project.yml         # dbt configuration
│   └── profiles.yml            # Connection profiles
└── scripts/
    └── snowflake_setup.sql     # Initial database setup
```

## CI/CD Workflows

### Pull Request Validation
- Validates Liquibase changelog syntax
- Compiles dbt models without execution
- Runs basic quality checks

### Development Deployment
- Auto-deploys on merge to main
- Runs full Liquibase + dbt pipeline
- Creates deployment artifacts

### Production Release
- Manual release process via GitHub releases
- Uses pre-built artifacts for consistency
- Tags database state for rollback

### Rollback Process
- Manual workflow for emergency rollbacks
- Supports both dev and prod environments
- Reverts database to tagged state

## Data Models

### Source Tables (Liquibase-managed)
- **CUSTOMERS**: Customer information and contact details
- **PRODUCTS**: Product catalog with pricing
- **ORDERS**: Order headers with customer relationships
- **ORDER_ITEMS**: Order line items with product details

### Analytics Models (dbt-managed)
- **customer_order_summary**: Customer lifetime value and segmentation
- **product_sales_analysis**: Product performance and ranking metrics

## Security & Permissions

### Service Accounts
- **LIQUIBASE_USER**: Full DDL permissions on PUBLIC schema
- **DBT_USER**: Read access to PUBLIC, full control of DBT schema

### Best Practices
- Environment-specific passwords and connection details
- Separate roles with minimum required permissions
- Encrypted secrets management in GitHub Actions

## Testing Strategy

### Liquibase Testing
- Changelog validation in CI/CD
- Rollback testing for schema changes
- Connection and permission validation

### dbt Testing
- Source data quality tests
- Model compilation validation
- Business logic testing with custom tests

## Troubleshooting

### Common Issues

**Local development setup issues:**
- Run `./scripts/setup-local.sh` to create .env file from template
- Verify .env file contains correct SNOWFLAKE_ACCOUNT format: `account.region.cloud`
- Ensure LIQUIBASE_PASSWORD and DBT_PASSWORD match users created in Snowflake
- Use wrapper scripts: `./scripts/liquibase-local.sh` and `./scripts/dbt-local.sh`

**Liquibase connection errors:**
- Check .env file exists and contains correct credentials
- Verify SNOWFLAKE_ACCOUNT format: `account.region.cloud`
- Ensure LIQUIBASE_USER has proper permissions in Snowflake

**dbt compilation failures:**
- Verify source tables exist in PUBLIC schema (run Liquibase first)
- Check DBT_USER read permissions on PUBLIC schema
- Validate dbt_project.yml configuration

**CI/CD pipeline failures:**
- Check GitHub secrets configuration
- Verify environment setup in repository settings
- Review workflow logs for specific error messages

### Getting Help
- Review GitHub Actions logs for detailed error information
- Check Liquibase Pro documentation for advanced features
- Consult dbt documentation for model development patterns

## Customization Guide

### Adding New Tables
1. Create new changeset in `liquibase/changelogs/releases/`
2. Add source definition in `dbt/models/staging/schema.yml`
3. Create corresponding dbt models if needed

### Environment Configuration
- Modify connection details in properties files
- Update GitHub secrets for new environments
- Adjust workflow triggers and deployment logic

### Extending Analytics
- Add new models in `dbt/models/marts/`
- Create staging models for complex transformations
- Implement data quality tests and documentation

## Support

For issues and questions:
- Check troubleshooting section above
- Review implementation-plan.md for step-by-step guidance
- Consult solution-guide.md for architectural decisions