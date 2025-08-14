# Implementation Plan: liquibase-snowflake-dbt

## Project Overview
Create a new Liquibase + dbt integration repository that demonstrates best practices for managing database schema changes and analytics transformations in Snowflake. This implementation follows the separation of concerns principle where Liquibase manages structural database changes and dbt manages data transformations.

## Implementation Progress Tracking
Mark each step with ✓ COMPLETED when finished. This helps track progress and ensures all steps are properly executed.

## Important: Solution Guide Reference
**Every step in this implementation should be built while referencing the `solution-guide.md` document in this directory.** The solution guide provides the architectural principles, best practices, and detailed rationale for the design decisions in this implementation. Key concepts to follow:
- Separation of duties between Liquibase (schema management) and dbt (transformations)
- Schema organization with PUBLIC for Liquibase-managed objects and DBT for dbt-managed objects
- Proper permission model with separate service accounts
- CI/CD automation patterns and workflows

## Prerequisites
- Snowflake account with appropriate permissions
- GitHub repository with Actions enabled
- Liquibase Pro license (for advanced features)
- dbt CLI installed locally for testing

## Implementation Steps

### Step 1: Create Repository Structure ✓ COMPLETED
Create the following directory structure in `repos/liquibase-snowflake-dbt/`:

```
liquibase-snowflake-dbt/
├── .github/
│   └── workflows/
│       ├── pr-validation.yml
│       ├── deploy-dev.yml
│       ├── release-prod.yml
│       └── rollback.yml
├── liquibase/
│   ├── changelogs/
│   │   ├── releases/
│   │   │   └── 1.0/
│   │   │       └── 001-initial-schema.sql
│   │   └── db.changelog-main.xml
│   ├── flowfiles/
│   │   ├── deploy.flowfile.yaml
│   │   └── validate.flowfile.yaml
│   ├── properties/
│   │   ├── liquibase.dev.properties
│   │   └── liquibase.prod.properties
│   └── liquibase.properties
├── dbt/
│   ├── models/
│   │   ├── staging/
│   │   │   └── schema.yml
│   │   └── marts/
│   │       ├── customer_order_summary.sql
│   │       ├── product_sales_analysis.sql
│   │       └── schema.yml
│   ├── dbt_project.yml
│   └── profiles.yml
├── scripts/
│   ├── snowflake_setup.sql
│   └── create_changelog_artifact.sh
├── README.md
├── repo-metadata.md
└── summary.md
```

### Step 2: Create Snowflake Setup Script ✓ COMPLETED

Create `scripts/snowflake_setup.sql` with the following content:

```sql
-- Database setup
CREATE DATABASE IF NOT EXISTS ONLINE_STORE_DB;
USE DATABASE ONLINE_STORE_DB;

-- Schema creation
CREATE SCHEMA IF NOT EXISTS PUBLIC;    -- For Liquibase-managed objects
CREATE SCHEMA IF NOT EXISTS DBT;       -- For dbt-managed transformations

-- Create service accounts
CREATE USER IF NOT EXISTS LIQUIBASE_USER PASSWORD = 'ChangeMe123!' DEFAULT_ROLE = 'LIQUIBASE_ROLE';
CREATE USER IF NOT EXISTS DBT_USER PASSWORD = 'ChangeMe456!' DEFAULT_ROLE = 'DBT_ROLE';

-- Create roles
CREATE ROLE IF NOT EXISTS LIQUIBASE_ROLE;
CREATE ROLE IF NOT EXISTS DBT_ROLE;

-- Grant database permissions
GRANT USAGE ON DATABASE ONLINE_STORE_DB TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON DATABASE ONLINE_STORE_DB TO ROLE DBT_ROLE;

-- Grant schema permissions
GRANT ALL ON SCHEMA PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON SCHEMA PUBLIC TO ROLE DBT_ROLE;
GRANT ALL ON SCHEMA DBT TO ROLE DBT_ROLE;

-- Grant future object permissions
GRANT ALL ON FUTURE TABLES IN SCHEMA PUBLIC TO ROLE LIQUIBASE_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PUBLIC TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE VIEWS IN SCHEMA DBT TO ROLE DBT_ROLE;

-- Assign roles to users
GRANT ROLE LIQUIBASE_ROLE TO USER LIQUIBASE_USER;
GRANT ROLE DBT_ROLE TO USER DBT_USER;

-- Create warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH WITH WAREHOUSE_SIZE = 'XSMALL';
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE LIQUIBASE_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DBT_ROLE;
```

### Step 3: Create Initial Liquibase Changelog

Create `liquibase/changelogs/releases/1.0/001-initial-schema.sql`:

```sql
--liquibase formatted sql

--changeset author:liquibase id:001-create-customers
CREATE TABLE IF NOT EXISTS PUBLIC.CUSTOMERS (
    customer_id NUMBER PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
--rollback DROP TABLE PUBLIC.CUSTOMERS;

--changeset author:liquibase id:002-create-products
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCTS (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
--rollback DROP TABLE PUBLIC.PRODUCTS;

--changeset author:liquibase id:003-create-orders
CREATE TABLE IF NOT EXISTS PUBLIC.ORDERS (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (customer_id) REFERENCES PUBLIC.CUSTOMERS(customer_id)
);
--rollback DROP TABLE PUBLIC.ORDERS;

--changeset author:liquibase id:004-create-order-items
CREATE TABLE IF NOT EXISTS PUBLIC.ORDER_ITEMS (
    order_item_id NUMBER PRIMARY KEY,
    order_id NUMBER NOT NULL,
    product_id NUMBER NOT NULL,
    quantity NUMBER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES PUBLIC.ORDERS(order_id),
    FOREIGN KEY (product_id) REFERENCES PUBLIC.PRODUCTS(product_id)
);
--rollback DROP TABLE PUBLIC.ORDER_ITEMS;
```

Create `liquibase/changelogs/db.changelog-main.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <includeAll path="releases/" relativeToChangelogFile="true"/>
</databaseChangeLog>
```

### Step 4: Configure Liquibase Properties

Create `liquibase/properties/liquibase.dev.properties`:

```properties
changeLogFile=liquibase/changelogs/db.changelog-main.xml
url=jdbc:snowflake://<account>.snowflakecomputing.com/?db=ONLINE_STORE_DB&schema=PUBLIC&warehouse=COMPUTE_WH
username=LIQUIBASE_USER
password=${LIQUIBASE_PASSWORD}
liquibase.hub.mode=off
```

Create `liquibase/properties/liquibase.prod.properties` with similar content but potentially different connection details.

### Step 5: Create Liquibase Flow Files

Create `liquibase/flowfiles/deploy.flowfile.yaml`:

```yaml
globalVariables:
  ENVIRONMENT: "${ENVIRONMENT:-dev}"

stages:
  validate:
    actions:
      - type: liquibase
        command: validate

  status:
    actions:
      - type: liquibase
        command: status
        cmdArgs: {verbose: true}

  deploy:
    actions:
      - type: liquibase
        command: update
        cmdArgs: {report-enabled: true, report-name: "deploy-${ENVIRONMENT}.html"}

  dbt:
    actions:
      - type: shell
        command: |
          cd dbt
          dbt run --target ${ENVIRONMENT}
          dbt test --target ${ENVIRONMENT}

  snapshot:
    actions:
      - type: liquibase
        command: snapshot
        cmdArgs: {output-file: "snapshot-${ENVIRONMENT}.json"}
```

### Step 6: Create dbt Models

Create `dbt/models/marts/customer_order_summary.sql`:

```sql
{{ config(
    materialized='table',
    schema='dbt'
) }}

WITH customer_orders AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS lifetime_value,
        AVG(o.total_amount) AS avg_order_value,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM {{ source('public', 'customers') }} c
    LEFT JOIN {{ source('public', 'orders') }} o ON c.customer_id = o.customer_id
    GROUP BY 1, 2, 3, 4
)

SELECT 
    *,
    DATEDIFF('day', first_order_date, last_order_date) AS customer_lifetime_days,
    CASE 
        WHEN lifetime_value > 1000 THEN 'High Value'
        WHEN lifetime_value > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_orders
```

Create `dbt/models/marts/product_sales_analysis.sql`:

```sql
{{ config(
    materialized='table',
    schema='dbt'
) }}

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.price AS current_price,
        COUNT(DISTINCT oi.order_id) AS times_ordered,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.line_total) AS total_revenue,
        AVG(oi.unit_price) AS avg_selling_price
    FROM {{ source('public', 'products') }} p
    LEFT JOIN {{ source('public', 'order_items') }} oi ON p.product_id = oi.product_id
    GROUP BY 1, 2, 3, 4
)

SELECT 
    *,
    total_revenue / NULLIF(total_quantity_sold, 0) AS revenue_per_unit,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER (PARTITION BY category ORDER BY total_quantity_sold DESC) AS category_rank
FROM product_sales
```

### Step 7: Configure dbt

Create `dbt/dbt_project.yml`:

```yaml
name: 'online_store_analytics'
version: '1.0.0'
config-version: 2

profile: 'snowflake'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

models:
  online_store_analytics:
    staging:
      +materialized: view
    marts:
      +materialized: table
```

Create `dbt/profiles.yml`:

```yaml
snowflake:
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: DBT_USER
      password: "{{ env_var('DBT_PASSWORD') }}"
      role: DBT_ROLE
      warehouse: COMPUTE_WH
      database: ONLINE_STORE_DB
      schema: DBT
      threads: 4
    prod:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: DBT_USER
      password: "{{ env_var('DBT_PASSWORD') }}"
      role: DBT_ROLE
      warehouse: COMPUTE_WH
      database: ONLINE_STORE_DB
      schema: DBT
      threads: 4
  target: dev
```

### Step 8: Create GitHub Actions Workflows

Create `.github/workflows/pr-validation.yml`:

```yaml
name: PR Validation

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Liquibase
        uses: liquibase-github-actions/setup-liquibase@v7.0.0
        with:
          liquibase-version: '4.29.0'
      
      - name: Validate Liquibase Changelog
        run: |
          liquibase validate \
            --defaults-file=liquibase/properties/liquibase.dev.properties
        env:
          LIQUIBASE_PASSWORD: ${{ secrets.LIQUIBASE_DEV_PASSWORD }}
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dbt
        run: |
          pip install dbt-snowflake
      
      - name: Test dbt Compilation
        run: |
          cd dbt
          dbt deps
          dbt compile --target dev
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          DBT_PASSWORD: ${{ secrets.DBT_DEV_PASSWORD }}
```

Create `.github/workflows/deploy-dev.yml`:

```yaml
name: Deploy to Dev

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Liquibase
        uses: liquibase-github-actions/setup-liquibase@v7.0.0
        with:
          liquibase-version: '4.29.0'
      
      - name: Deploy Database Changes
        run: |
          liquibase flow \
            --flow-file=liquibase/flowfiles/deploy.flowfile.yaml \
            --defaults-file=liquibase/properties/liquibase.dev.properties
        env:
          LIQUIBASE_PASSWORD: ${{ secrets.LIQUIBASE_DEV_PASSWORD }}
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          DBT_PASSWORD: ${{ secrets.DBT_DEV_PASSWORD }}
          ENVIRONMENT: dev
      
      - name: Create Changelog Artifact
        run: |
          mkdir -p artifacts
          zip -r artifacts/changelog-${{ github.sha }}.zip \
            liquibase/changelogs \
            liquibase/properties \
            liquibase/flowfiles \
            dbt/
      
      - name: Upload Changelog Artifact
        uses: actions/upload-artifact@v3
        with:
          name: changelog-${{ github.sha }}
          path: artifacts/changelog-${{ github.sha }}.zip
          retention-days: 90
```

Create `.github/workflows/release-prod.yml`:

```yaml
name: Release to Production

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod
    
    steps:
      - name: Download Release Artifact
        uses: actions/download-artifact@v3
        with:
          name: changelog-${{ github.event.release.target_commitish }}
          path: release-artifact
      
      - name: Unzip Artifact
        run: |
          unzip release-artifact/changelog-*.zip -d deployment
      
      - name: Setup Liquibase
        uses: liquibase-github-actions/setup-liquibase@v7.0.0
        with:
          liquibase-version: '4.29.0'
      
      - name: Deploy to Production
        run: |
          cd deployment
          liquibase flow \
            --flow-file=liquibase/flowfiles/deploy.flowfile.yaml \
            --defaults-file=liquibase/properties/liquibase.prod.properties
        env:
          LIQUIBASE_PASSWORD: ${{ secrets.LIQUIBASE_PROD_PASSWORD }}
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          DBT_PASSWORD: ${{ secrets.DBT_PROD_PASSWORD }}
          ENVIRONMENT: prod
      
      - name: Tag Database State
        run: |
          cd deployment
          liquibase tag \
            --tag=${{ github.event.release.tag_name }} \
            --defaults-file=liquibase/properties/liquibase.prod.properties
        env:
          LIQUIBASE_PASSWORD: ${{ secrets.LIQUIBASE_PROD_PASSWORD }}
```

Create `.github/workflows/rollback.yml`:

```yaml
name: Rollback

on:
  workflow_dispatch:
    inputs:
      target_tag:
        description: 'Tag to rollback to'
        required: true
        type: string
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - dev
          - prod

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Liquibase
        uses: liquibase-github-actions/setup-liquibase@v7.0.0
        with:
          liquibase-version: '4.29.0'
      
      - name: Rollback Database
        run: |
          liquibase rollback \
            --tag=${{ inputs.target_tag }} \
            --defaults-file=liquibase/properties/liquibase.${{ inputs.environment }}.properties
        env:
          LIQUIBASE_PASSWORD: ${{ secrets[format('LIQUIBASE_{0}_PASSWORD', upper(inputs.environment))] }}
      
      - name: Revert dbt Models
        run: |
          echo "dbt model rollback would be handled by reverting to previous code version"
          echo "This is typically done through git revert or checking out previous tag"
```

### Step 9: Create Documentation

Create comprehensive README.md with:
- Project overview
- Setup instructions
- Workflow descriptions
- Troubleshooting guide

Create repo-metadata.md following the standard template with:
- Technology stack details
- Use case description
- Implementation highlights

Create summary.md with AI-optimized descriptions for pattern discovery.

### Step 10: GitHub Repository Configuration

Set the following secrets in GitHub:
- `SNOWFLAKE_ACCOUNT`
- `LIQUIBASE_DEV_PASSWORD`
- `LIQUIBASE_PROD_PASSWORD`
- `DBT_DEV_PASSWORD`
- `DBT_PROD_PASSWORD`

Create environments:
- `dev` - Auto-deploy on merge to main
- `prod` - Requires manual approval

## Testing Instructions

1. Run Snowflake setup script to create database objects
2. Test Liquibase deployment locally
3. Test dbt models locally
4. Create PR to test validation workflow
5. Merge to main to test dev deployment
6. Create release to test prod deployment
7. Test rollback workflow

## Success Criteria

- PR validation catches schema and model errors
- Dev deployments complete automatically on merge
- Changelog artifacts are created and stored
- Release process successfully deploys to production
- Rollback can revert database changes
- Clear separation between Liquibase and dbt responsibilities