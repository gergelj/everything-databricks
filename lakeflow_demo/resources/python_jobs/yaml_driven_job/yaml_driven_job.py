from pathlib import Path

import yaml
from databricks.bundles.core import Bundle, Resources
from databricks.bundles.jobs import Job, Task, RunJobTask


# Load job configuration from the YAML file next to this script
config_path = Path(__file__).parent / "job_config.yml"
with open(config_path) as f:
    config = yaml.safe_load(f)


def load_resources(bundle: Bundle) -> Resources:
    """Generate one job per entry in the 'jobs' list from job_config.yml."""

    resources = Resources()

    for job_cfg in config["jobs"]:
        job = Job(
            name=job_cfg["name"],
            tasks=[Task(
                task_key="run_parameterized_job",
                run_job_task=RunJobTask(
                    job_id="${resources.jobs.parameterized_job.id}",
                    job_parameters={"greeting": job_cfg["parameters"]["greeting"]},
                ),
            )],
        )

        resources.add_job(job_cfg["name"], job)

    return resources
