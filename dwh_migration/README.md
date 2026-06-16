# README

## Prerequisites
- [Partner-powered AI features](https://docs.databricks.com/aws/en/databricks-ai/partner-powered) enabled in the account/workspace
- `ai-dev-kit` skills installed
    1. clone the [repository](https://github.com/databricks-solutions/ai-dev-kit)
    2. run the following command: `./databricks-skills/install_skills.sh --install-to-genie --profile <DATABRICKS_PROFILE>`

## How to use

Save the **MIGRATION.md** document in your workspace and fill out the Input Parameters section with your information. After, execute the different Milestones with Genie Code prompt-by-prompt:

- Create a migration plan document:
    ```
    > Execute Milestone 1 in @MIGRATION.md
    ```

- Create a technical plan (mapping document):
    ```
    > Execute Milestone 2 in @MIGRATION.md
    ```

- Do the conversion:
    ```
    > Execute Milestone 3 in @MIGRATION.md
    ```

In between the prompts you can stop and review the documents and amend changes to them.