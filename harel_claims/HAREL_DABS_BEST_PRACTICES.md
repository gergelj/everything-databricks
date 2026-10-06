# Declarative Automation Bundles: best practices for Harel

*A one-page summary to share after the session.*

## The model

```
 feature branch ──PR──▶ CI: lint · unit tests · bundle validate --strict · bundle plan
                          │
                        merge to main
                          ▼
                 CD: deploy staging (as SP) ─▶ integration run + quality gates
                          │
                     manual approval
                          ▼
                 CD: bundle plan + deploy prod (as SP)
```

## Do

- **Put everything a workload needs in the bundle:** code, jobs, pipelines, schemas, volumes,
  dashboards, and permissions.
- **Use three targets.** `dev` uses `mode: development` (per-engineer isolated copies).
  `staging` and `prod` use `mode: production`.
- **Parameterise environment differences** with `variables` and `${...}` substitutions:
  catalog, hosts, service principals, alert emails.
- **Run staging and prod as service principals** with `run_as`, and deploy from CI as a service
  principal.
- **Use keyless CI auth:** GitHub OIDC or Azure DevOps Workload Identity Federation. Don't store
  PATs or client secrets.
- **Declare permissions in YAML.** In prod, give humans view or run access only.
- **Add guardrails:** `git.branch: main` on prod, a pinned `databricks_cli_version`,
  `validate --strict` in every PR, and `bundle plan` before every deploy.
- **Keep logic in Python modules or packages** with unit tests that run without a workspace.
  Integration-test in staging.
- **Use one bundle per domain or team**, and a custom `bundle init` template for shared standards.
- **Bind catalogs to environment workspaces** (`harel_dev`, `harel_stg`, `harel_prod`).

## Don't

- Deploy staging or prod from a laptop.
- Edit bundle-managed jobs or pipelines in the UI. The next deploy reverts the change.
- Hardcode catalogs, workspace IDs, or cluster IDs, or write `if env == "prod"` logic.
- Put `--force` / `--force-lock` in pipelines as a "fix".
- Put secrets in bundle config. Use secret scopes (Key Vault-backed).

## Adopting existing workloads

```bash
databricks bundle generate job --existing-job-id <id> --key my_job      # YAML + source from an existing job
databricks bundle deployment bind my_job <id> -t prod                   # manage the existing job in place
```

## Command cheat sheet

| Command | Use |
|---|---|
| `databricks bundle init [default-python \| pydabs \| <git-url>]` | Start a new project |
| `databricks bundle validate --strict -t <target>` | Check config (warnings fail) |
| `databricks bundle plan -t <target>` | Preview the create, update, and delete actions |
| `databricks bundle deploy -t <target>` | Deploy (idempotent) |
| `databricks bundle run <resource_key> -t <target>` | Run a job, pipeline, or app |
| `databricks bundle summary -t <target>` | What's deployed, with links |
| `databricks bundle destroy -t dev` | Remove your dev copy |

**Docs:** https://docs.databricks.com/dev-tools/bundles/ ·
**Examples:** https://github.com/databricks/bundle-examples
