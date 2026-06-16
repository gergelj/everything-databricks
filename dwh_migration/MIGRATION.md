# Data Warehouse Migration Executor

## Input Parameters:

- Source System: [change this]
- Data Sources:
    - [change this] example: SQL Server - Lakeflow Connect
    - [change this] example: S3 bucket - AutoLoader
    - etc.
- Target Technology: Spark Declarative Pipeline (SQL or Python)
- Root Project Directory: [change this]
- Input Directory (source files): [change this]
- Output Directory (converted files): [change this]
- Output Format: Declarative Automation Bundle

## Instructions for Genie:
- Replace every reference of {Variable} with the value from the Input Parameters section. 
- Load the ai-dev-kit skills from `/Workspaces/Users/<current_user>/.assistant` before every conversation with Genie.

## Milestone 1: Migration plan

Create a migration plan document that converts from {Source System} to Databricks {Target Technology}. This document should have the name **MIGRATIONPLAN.md** and should be created in {Root Project Directory}.

Chapters to include in the document:

1. Executive Summary — Business drivers, target state (e.g., migrating to Databricks Lakehouse), timeline, and success criteria.

2. Current State Assessment — Inventory of existing objects in the {Input directory} dependencies, and known pain points.

3. Target Architecture — Lakehouse design (bronze/silver/gold layers), compute strategy, storage layout, Unity Catalog structure (catalogs, schemas), and security model.

4. Migration Strategy — Approach selection (lift-and-shift, re-engineer, or hybrid), prioritization framework, and wave/phase breakdown.

5. Detailed Wave Plan — Per-wave scope (which schemas/tables/pipelines), dependencies, acceptance criteria, and rollback procedures.

6. ETL/Pipeline Conversion — Mapping of legacy ETL to {Target Technology}, transformation logic translation, and scheduling.

7. Data Validation & Reconciliation — Row counts, checksums, business-rule checks, and comparison queries between source and target.

8. Performance & Optimization — Benchmarks, clustering strategy, caching, and query tuning targets.

9. Security & Governance — Role mapping, access controls, data classification, lineage, and compliance requirements.

10. Cutover & Decommission Plan — Parallel-run period, switchover steps, consumer notification, and legacy system retirement timeline.

11. Risk Register & Mitigations — Known risks (data drift, downtime, skill gaps) with owners and contingency plans.

12. RACI & Communication Plan — Stakeholder roles, escalation paths, status cadence, and go/no-go decision gates.

## Milestone 2: Technical plan

Analyze the source files in {Input Directory} and generate a document with a technical mapping from {Source System} to Databricks. Use {Target Technology} and use the best practices skills. Generalize this document so it can be applied for the actual converting process across all source code. This document should have the name **TECHNICALPLAN.md** and should be created in {Root Project Directory}.

## Milestone 3: Convert to Databricks

According to the **TECHNICALPLAN.md** document in {Root Project Directory}, convert the source code in {Input Directory} to Databricks. The converted resources should be saved in {Output Directory} as {Output Format}.
