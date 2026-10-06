# Harel: CI/CD with Declarative Automation Bundles (DABs). Demo guide

**Audience:** Harel data engineering, platform/DevOps, and possibly security and architecture.
**Goal:** move Harel from "it works in my workspace" to repeatable, reviewable, keyless promotion
dev → staging → prod, with DABs as the single source of truth.
**Length:** about 75 min (45 min demo and talk, 30 min Q&A and discussion of their setup).
**Demo assets:** `harel_claims/` is an insurance claims bundle: UC schema and volume, an SDP pipeline,
a job with wheel tasks, unit tests, and GitHub Actions and Azure DevOps pipelines.

> Things to confirm with the account team before the session: cloud (Azure assumed), CI tool
> (Azure DevOps or GitHub), whether they use one workspace per environment, how they deploy today
> (UI, Repos/Git folders, `dbx`, Terraform, REST scripts?), and whether they use Unity Catalog fully.
> The bundle includes both CI flavours. Show the one they use.

---

## 1. What to cover (and why)

| # | Topic | Key message | Time |
|---|-------|-------------|------|
| 1 | Why DABs | One repo describes code, infrastructure, and permissions together. Deploy is idempotent and the same in every environment. | 5 |
| 2 | Anatomy of a bundle | `databricks.yml`, `resources/*.yml`, `src/`, artifacts, `include` | 5 |
| 3 | Targets and modes | `development` gives isolated copies per engineer. `production` adds guardrails. | 8 |
| 4 | Parameterisation | Variables and substitutions. Never hardcode a catalog, host, or ID. | 5 |
| 5 | Identity and permissions | `run_as` service principal, permissions in code, humans read-only in prod | 7 |
| 6 | Testing strategy | Unit tests with no workspace, integration runs in staging, quality gates as job tasks | 5 |
| 7 | CI/CD pipeline | PR runs validate, test, and plan. Merge deploys staging and runs it. Approval deploys prod. Keyless OIDC/WIF. | 10 |
| 8 | Brownfield adoption | `bundle generate` and `bundle deployment bind` for existing jobs and pipelines | 3 |
| 9 | Anti-patterns and scaling | What goes wrong at scale, custom templates, repo layout | 5 |
| | Q&A and their environment | | 20–30 |

---

## 2. Core principles (the "using DABs correctly" part)

Treat these as the backbone of the talk. Every demo step should illustrate one of them.

1. **The bundle is the source of truth for everything it deploys.** That includes code, jobs,
   pipelines, schemas, volumes, dashboards, apps, and **permissions**. Nobody edits a
   bundle-managed resource in the UI in staging or prod. The next deploy overwrites UI changes.
2. **Build once and promote the same commit.** Staging and prod deploy from the same commit on
   `main`. Environment differences live only in `targets:` and variables, never in
   `if env == "prod"` branches in code.
3. **Each engineer gets an isolated dev copy.** `mode: development` prefixes names
   (`[dev alice] harel_claims_daily`), prefixes UC schemas (`dev_alice_claims`), pauses
   schedules, and sets pipelines to development mode. Engineers can't collide with each other or
   with prod. `bundle destroy` cleans up.
4. **Workloads run as service principals, and CI deploys as a service principal.** Use `run_as` in
   staging and prod. CI authenticates with **workload identity federation** (GitHub OIDC, or an Azure
   DevOps WIF service connection). No PATs and no client secrets stored in CI.
5. **Least privilege for humans in prod.** Use `CAN_VIEW` or `CAN_RUN` for groups. Only the
   deploying SP gets `CAN_MANAGE`. Changes reach prod through a pull request and nothing else.
6. **Guardrails are config, not tribal knowledge.**
   - `mode: production` blocks dev-mode pipelines and user-scoped paths.
   - `git.branch: main` on prod makes a deploy from a feature branch fail.
   - `databricks_cli_version` pins the CLI, so laptops and CI behave the same.
   - `validate --strict` turns warnings into errors.
   - `bundle plan` shows exactly what will change, for review and audit.
7. **Real code goes in tested Python modules or packages, not giant notebooks.** Business rules
   (`claims_logic.py`) are unit-tested on a laptop or CI agent with local Spark. Integration runs
   on real data happen in staging.
8. **Right-size the bundle.** Use one bundle per deployable domain or team (e.g. claims, policies,
   actuarial). Not one bundle per notebook, and not one mega-bundle for the whole company. Use a
   **custom `bundle init` template** to standardise layout, CI, and naming across teams.
9. **Use separate workspaces per environment, with catalogs bound to them.** `harel_dev`,
   `harel_stg`, and `harel_prod` catalogs with workspace-catalog bindings, so a dev workspace
   can't even see prod data.
10. **Use the direct deployment engine.** It's the default in current CLIs (Terraform is
    deprecated) and gives faster deploys and `bundle plan`. Existing bundles can migrate (see
    docs/dev-tools/bundles/direct).

### Anti-patterns to call out explicitly

| Anti-pattern | Why it hurts | Instead |
|---|---|---|
| Deploying prod from a laptop | No review, no audit, the prod job runs as a person | Prod is deployed only by CD, with an approval gate |
| PAT stored as a CI secret | Long-lived, personal, leaks | OIDC / WIF federation to an SP |
| Hardcoded `catalog = "prod"` in notebooks | Code can't be promoted | Variables, then job/pipeline parameters, then code reads its config |
| `if target == "prod":` logic in code | Behaviour differs by environment and staging tests prove nothing | Differences only in `targets:` |
| Editing bundle jobs in the UI | Drift that the next deploy silently reverts | Change YAML and open a PR. Use `bundle generate` to capture a UI prototype |
| Shared "dev" job edited by everyone | Collisions and broken demos | `mode: development` per-user copies |
| One bundle per notebook | Hundreds of pipelines and no shared releases | One bundle per domain |
| `--force` / `--force-lock` in CI scripts | Bypasses the guardrails | Fix the cause. Keep a `concurrency` group on deploy jobs |
| No tests until prod | Bugs reach prod | Unit tests in PR, integration and quality gates in staging |

---

## 3. Pre-demo checklist

- [ ] A demo workspace (FEVM is fine) with Unity Catalog. Ideally use **two workspaces**, or at
      least two catalogs, to show dev vs staging.
- [ ] Create catalogs `harel_dev` and `harel_stg`. Or rename them in `databricks.yml` to catalogs
      that exist.
- [ ] Replace placeholder hosts and SP application IDs in `harel_claims/databricks.yml`.
- [ ] Create a service principal for staging. Grant it `USE CATALOG` and `CREATE SCHEMA` on
      `harel_stg`, and make it a member of the `harel-claims-engineers` group (or change the group names).
- [ ] Push `harel_claims/` to a demo GitHub repo (or Azure DevOps project). Set up the SP
      federation policy and the `staging` / `prod` environments, with required reviewers on `prod`.
- [ ] Run the full flow once the day before: dev deploy, PR, merge, staging run, prod approval.
      **Pre-run CD once** so a green history exists if live CI is slow.
- [ ] Local: `uv sync --group dev`, Java 17 or 21 for local tests (Spark 4.0 does not run on Java 25).
- [ ] Pre-open browser tabs: workspace Jobs UI, Pipelines UI, Catalog Explorer, the CI runs page.

---

## 4. Demo script

### Act 1: The bundle (≈10 min)

1. **Open `databricks.yml`.** Walk through `bundle`, the CLI pin, `include`, `artifacts`
   (wheel built with `uv build`), `variables`, and the three targets.
   - *Say:* "Everything that differs between environments is on this screen. The rest of the
     repo is identical in dev, staging, and prod."
2. **Open `resources/`.** Point out that the schema and volume are resources too. Show the pipeline
   referencing `${resources.schemas.claims.name}`, and the job referencing
   `${resources.pipelines.claims_etl.id}`. These are references, not IDs, and they give
   dependency ordering for free.
3. **Show `src/claims_etl/`:** one file per table, plus expectations (data quality rules) on
   silver. Then `claims_logic.py`: plain functions, imported by the pipeline and by the tests.
4. **Point out the target-scoped resource:** the `sample_data` job exists only in dev and staging
   (YAML anchor). Prod never gets synthetic data.

### Act 2: Developer inner loop (≈10 min)

```bash
cd harel_claims
uv run pytest -v                        # green in ~10s, no workspace needed
databricks bundle validate --strict     # dev target is the default
databricks bundle plan                  # what will be created
databricks bundle deploy                # isolated dev copy
databricks bundle run sample_data
databricks bundle run claims_daily
```

In the UI, show:
- Job name `[dev <you>] harel_claims_daily`, schedule **paused**, and the job tagged.
- Schema `harel_dev.dev_<you>_claims` with bronze, silver, and gold tables.
- Pipeline in development mode, with the expectations tab showing dropped bad records (about 2%
  of rows have a null `policy_id`).

**Live change:** edit the schedule in `claims_daily.job.yml` (6:00 → 7:00), then run
`databricks bundle plan`. The output shows a single update. *Say:* "This is what a reviewer sees
in the PR."

**Drift demo (optional):** edit the dev job in the UI, then redeploy. The YAML wins. The UI also
shows a banner that the job is bundle-managed.

### Act 3: CI/CD (≈15 min)

1. Open `.github/workflows/ci.yml` (or `azure-pipelines.yml`) and walk through it.
   - **No secrets:** `id-token: write` with `DATABRICKS_AUTH_TYPE: github-oidc`. On ADO, a WIF
     service connection with `azure-cli` auth.
   - The PR job runs lint, pytest, `validate --strict -t staging`, and `plan -t staging`.
2. **Make the change from Act 2 on a branch and open a PR.** CI goes green, and the plan output
   appears in the logs.
3. **Merge.** CD deploys staging as the SP, then runs `sample_data`, then `claims_daily`. The
   quality gate task is the integration test. If it fails, prod never happens.
4. Show the staging job in the UI: the name has **no prefix**, *Run as* is the **service
   principal**, and the permissions match YAML (engineers can manage in staging, but are
   view-only in prod).
5. **Approval gate:** the prod job waits for reviewers. Approve it, and CD runs `plan` then
   `deploy` to prod.

**Guardrail moments** (pick one or two):
- On a feature branch, run `databricks bundle deploy -t prod`. It fails on `git.branch: main`.
- Introduce a typo in a resource field, then run `databricks bundle validate --strict`. It fails
  in seconds, before anything is deployed.
- Delete the pipeline resource and run `bundle plan`. The plan shows a **delete**, which is
  exactly what a reviewer must catch. (Deploy also asks for confirmation on destructive changes.
  This is why `--auto-approve` lives only behind the approval gate.)

### Act 4: Brownfield adoption (≈3 min)

"You already have jobs built in the UI. You don't have to start over."

```bash
databricks bundle generate job --existing-job-id <id> --key claims_legacy
databricks bundle deployment bind claims_legacy <id> -t prod   # adopt in place, keep run history
```

---

## 5. Likely questions

| Question | Answer |
|---|---|
| How is this different from Git folders (Repos)? | Git folders are for *authoring* in the workspace. DABs are for *deploying* jobs, pipelines, and permissions. Use both: develop in a Git folder, then deploy with a bundle. |
| Terraform vs DABs? | Use Terraform (or the platform team's IaC) for **platform**: workspaces, metastores, catalogs, network, groups. Use DABs for **workload**: jobs, pipelines, schemas, dashboards, apps owned by the data team. |
| Can we deploy only part of a bundle? | `bundle deploy --select jobs.claims_daily`. This is useful for hotfixes, but full deploys should stay the norm. |
| What if a job is running during deploy? | Deploy doesn't kill runs. Use `--fail-on-active-runs` in prod if you want to block instead. |
| Notebooks vs Python files? | Both work. Keep notebooks thin and put logic in modules or packages so it can be tested. |
| Monorepo with many teams? | Use one bundle per domain folder. CI uses path filters to validate and deploy only changed bundles. Share standards through a custom `bundle init` template. |
| Can bundles be written in Python instead of YAML? | Yes, with `pydabs` (`databricks bundle init pydabs`). This helps when resources are generated, for example 50 similar ingestion jobs from a config table. |
| Secrets in jobs? | Use Databricks secret scopes (Key Vault-backed on Azure), referenced from code. Never put them in the bundle or in variables. |
| Who can see/deploy prod? | Only the prod SP has `CAN_MANAGE`. Humans get view or run access through groups, all defined in `databricks.yml` and reviewed in PRs. |
| ML models? | The same bundle can hold `registered_models` and `experiments`. For a full MLOps layout, see `databricks bundle init mlops-stacks`. |
| Rollback? | Revert the commit on `main`. CD redeploys the previous state. Because deploys are declarative, a rollback is just another deploy. |

---

## 6. Suggested next steps to propose

1. **Workshop (half day):** convert one real Harel workload with `bundle generate` and `bind`.
2. **Platform setup:** SPs per environment, federation policies, catalog bindings, CI templates.
3. **Custom `bundle init` template** that encodes Harel standards (naming, tags, CI, run_as),
   so every new project starts compliant.
4. Optional: deploy dashboards (`.lvdash.json`) and Databricks Apps through the same pipeline.
