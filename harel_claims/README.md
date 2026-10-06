# harel_claims

Claims analytics on Databricks, deployed with a Declarative Automation Bundle (DAB).

```
databricks.yml                  bundle config: variables, targets (dev / staging / prod), run_as, permissions
resources/
  claims.schema.yml             UC schema + landing volume
  claims_etl.pipeline.yml       Lakeflow Spark Declarative Pipeline (bronze -> silver -> gold)
  claims_daily.job.yml          daily job: refresh pipeline, then quality gates
src/
  claims_etl/                   pipeline source (root_path)
    claims_logic.py             business rules, unit-tested
    transformations/            one file per table
  harel_claims/                 Python package built into a wheel for job tasks
tests/                          pytest + local Spark, runs in CI without a workspace
.github/workflows/              GitHub Actions CI (PR) and CD (main -> staging -> prod)
azure-pipelines.yml             Azure DevOps equivalent
```

## Environments

| Target    | Who deploys        | Runs as                | Names / schema                          | Schedules |
|-----------|--------------------|------------------------|-----------------------------------------|-----------|
| `dev`     | each engineer      | the engineer           | `[dev <user>] …`, `dev_<user>_claims`   | paused    |
| `staging` | CI, on merge       | staging SP             | `harel_stg.claims`                      | active    |
| `prod`    | CD, after approval | prod SP                | `harel_prod.claims`                     | active    |

## Developer loop

```bash
uv sync --group dev
uv run pytest                                    # unit tests, needs Java 17/21

databricks bundle validate --strict              # dev is the default target
databricks bundle deploy                         # your own isolated copy
databricks bundle run sample_data                # land synthetic claims
databricks bundle run claims_daily               # pipeline + quality gates
databricks bundle destroy                        # clean up when done
```

Never deploy `staging` or `prod` from a laptop. CI/CD does that, using a service principal.

## One-time setup per environment

1. Create a service principal per environment (staging, prod); add it to the workspace.
2. Grant it `USE CATALOG`, `CREATE SCHEMA` on the env catalog (`harel_stg`, `harel_prod`).
3. Set up keyless CI auth:
   - **GitHub Actions**: add a federation policy on the SP for `repo:<org>/<repo>:environment:<env>`,
     then set the `DATABRICKS_HOST` and `DATABRICKS_CLIENT_ID` variables on the `staging` / `prod` environments.
   - **Azure DevOps**: create an ARM service connection with Workload Identity Federation for each env,
     and add the identity behind it to the workspace.
4. Add required reviewers to the `prod` environment.
5. Replace the placeholder hosts and SP application IDs in `databricks.yml`.
