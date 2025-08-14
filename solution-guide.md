# Liquibase + dbt Integration Solution Brief for Snowflake

## Executive Summary

This solution brief outlines the recommended approach for integrating Liquibase and dbt with Snowflake, based on industry best practices and proven implementations. The solution leverages the strengths of each tool: Liquibase for schema version control and database change management, and dbt for data transformation and analytics engineering. This separation of concerns approach enables organizations to maintain compliance requirements while allowing rapid iteration on analytics models.

## Solution Overview

### Core Principle: Separation of Duties

The solution implements a clear architectural boundary where each tool manages what it was designed for. When thinking about database deployment holistically, there are three phases: pre-deployment, deployment, and post-deployment. In a pure data pipeline perspective, especially with ELT patterns, dbt naturally comes into play during the transformation phase. Everything related to the Extract and Load phases, particularly anything prior to the bronze layer in a medallion architecture, should be handled by Liquibase.

This separation addresses a fundamental challenge where two different systems compete for the privilege to manage database objects. By establishing clear ownership boundaries, the solution eliminates this competition while maintaining the flexibility to handle complex cross-schema dependencies.

### Why Both Tools Are Necessary

Organizations cannot simply use dbt for everything because forcing dbt to behave outside its intended purpose creates unnecessary complexity. The current approach of converting dbt models into scripts for Liquibase deployment doesn't leverage either tool's strengths. Instead, each tool should manage objects according to its core competencies.

**Liquibase provides:**
- Version control for schema changes
- Rollback capabilities for production issues
- Audit trails for compliance
- Performance optimization control
- Management of database objects that have nothing to do with transformation (stored procedures, functions, APIs)

**dbt provides:**
- Rapid iteration on business logic
- Built-in testing framework
- Automatic documentation and lineage
- Optimized transformation workflows

## Solution Architecture

### Component Setup

The solution requires the following architectural components:

#### 1. Repository Structure
- Single Git repository containing both Liquibase changelogs and dbt models
- Liquibase changelogs in a dedicated folder (e.g., /liquibase)
- dbt project in its standard structure (e.g., /dbt)
- Shared CI/CD configuration files

#### 2. Snowflake Schema Organization
- **Public Schema**: Managed by Liquibase for source tables and static objects
- **dbt Schema**: Managed by dbt for all transformation models and views
- Separate service accounts for each tool with appropriate permissions
- Clear naming conventions to distinguish object ownership

#### 3. Object Management Boundaries

**Liquibase Manages:**
- Source tables (customers, orders, transactions)
- Staging area tables
- Any objects prior to the bronze layer
- Stored procedures, functions, and database APIs
- Indexes, constraints, and performance optimizations

**dbt Manages:**
- All transformation logic
- Views and materialized views
- Transient tables
- Business logic models
- Anything in the transformation layer

#### 4. Liquibase Flow Configuration

Flow files orchestrate the deployment process, ensuring proper execution order. The flow capability enables orchestration of multiple steps, including running Liquibase migrations first, executing dbt models, and creating snapshots for future comparisons. There may also be post-dbt steps to execute. All of this can be managed in the Flowfile.

### Permission Model

The solution addresses the critical requirement that dbt must have permission to be used as a deployment tool. Without this permission, teams are forced to convert models into scripts for Liquibase deployment, which defeats the purpose of using dbt. The solution grants dbt appropriate permissions to create and manage its own objects in production, while maintaining audit trails through source control.

As a best practice, dbt and Liquibase-managed objects should be stored in separate schemas. They should also use different service accounts with permissions scoped to the correct schema to ensure that each tool can only manage its designated objects. This isolation prevents developers from accidentally managing a given object with the wrong tool.

## Developer Workflow

### Standard Development Process

1. **Identify Requirements**
   - Developer receives new business requirement
   - Determines what source data and transformations are needed
   - Plans both schema changes and model development

2. **Local Development**
   - Developer works in personal schema (clone of dev environment)
   - Creates/modifies dbt models as needed
   - Identifies source table requirements from model dependencies

3. **Schema Change Management**
   - For new source tables: Create Liquibase changesets with CREATE TABLE
   - For modifications: Create Liquibase changesets with ALTER TABLE
   - Ensure all columns referenced in dbt models exist in source tables

4. **Coordinated Changes**
   - Both Liquibase changelogs and dbt models committed together
   - Single PR contains all related changes
   - PR description documents the relationship between schema and models

5. **Testing**
   - Local testing in developer's personal schema
   - Run Liquibase update to apply schema changes
   - Run dbt build to create/update models
   - Validate data quality and transformations

### Handling Schema Evolution Example

For example, when adding a new column to support a model change:
1. Developer modifies the dbt model to use the new column
2. Creates Liquibase changelog to add column to source table
3. Commits both changes in same PR
4. CI/CD ensures Liquibase runs first, making column available for dbt

This workflow ensures dbt never fails due to missing base objects while maintaining clean separation between structural changes and transformation logic.

## CI/CD Automation

### Pipeline Architecture

The automation pipeline implements several key capabilities to ensure reliable deployments:

#### 1. PR Validation Pipeline
- Triggered on every pull request
- Creates ephemeral Snowflake schema using branch name: PR_[BRANCH]_[TIMESTAMP]
- Leverages Snowflake's zero-copy cloning for efficiency
- Runs complete deployment in isolated environment
- Automatically cleanup schema after validation

#### 2. Deployment Pipeline Sequence

1. **Pre-deployment Checks**
   - Validate Liquibase changelogs
   - Run policy checks (no unauthorized DROPs)
   - Verify dbt model syntax

2. **Schema Deployment (Liquibase)**
   - Apply all DDL changes
   - Create/modify source tables
   - Update constraints and indexes
   - Log all changes to audit table

3. **Transformation Deployment (dbt)**
   - Build all models in dependency order
   - Create/replace views and tables
   - Run dbt tests
   - Generate documentation

4. **Post-deployment Tasks**
   - Create Liquibase snapshot for future comparisons
   - Run data quality validations
   - Update deployment metadata

#### 3. Environment Progression
- **Development**: Developers can modify schemas directly for experimentation
- **Staging**: Only CI/CD pipeline can deploy, mirrors production constraints
- **Production**: Fully automated, no manual access, complete audit trail

### Advanced Automation Features

#### Liquibase Diff Changelog Generation
To address the challenge of manual changelog creation:
- Developer makes changes directly in sandbox environment
- Runs Liquibase flow to generate diff changelog
- Reviews and commits generated changelog
- Reduces manual effort while maintaining control

#### Dynamic Schema Management
- Each PR gets isolated schema with dynamic naming
- Environment variables pass schema names to both tools
- Supports parallel PR testing without conflicts
- Automatic cleanup prevents schema proliferation

#### Coordinated Rollback Capability
- Liquibase maintains rollback scripts for schema changes
- dbt models can be reverted through Git
- Coordinated rollback procedure ensures consistency

## Implementation Best Practices

### Schema Design Patterns
- Use consistent prefixes: SRC_ for source tables, STG_ for staging
- Separate schemas prevent object naming conflicts
- Clear ownership boundaries reduce confusion
- Enable parallel development without interference

### Change Management Guidelines
- Never use SELECT * in dbt models (explicitly list columns)
- Document schema dependencies in PR templates
- Review both DDL and model changes together
- Test rollback procedures for critical changes
- Maintain clear audit trail for compliance

### Migration Path
For organizations currently trying to generate DDL from dbt models:
- **Phase 1**: Establish schema separation and permissions
- **Phase 2**: Enable dbt to manage its own objects in production
- **Phase 3**: Implement full CI/CD automation
- **Phase 4**: Optimize based on team feedback and metrics

## Benefits and Outcomes

This solution delivers several key benefits:
- **Compliance**: Full audit trail and rollback capabilities for all schema changes
- **Agility**: Analytics engineers can iterate rapidly on business logic
- **Reliability**: Clear ownership prevents conflicts and confusion
- **Scalability**: Supports multiple teams working in parallel
- **Maintainability**: Each tool used for its intended purpose

## Conclusion

The Liquibase + dbt integration pattern represents a mature approach to modern data platform management. By respecting the fundamental principle that Liquibase manages structure while dbt manages transformation, organizations can achieve both the control required for enterprise data governance and the agility demanded by modern analytics. The solution acknowledges that database deployment is not monolithic but rather a series of coordinated steps, each best handled by purpose-built tools working in concert.