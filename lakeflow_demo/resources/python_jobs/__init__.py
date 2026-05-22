from databricks.bundles.core import (
    Bundle,
    Resources,
    load_resources_from_current_package_module,
)

from .yaml_driven_job.yaml_driven_job import load_resources as load_yaml_driven_jobs


def load_resources(bundle: Bundle) -> Resources:
    """
    'load_resources' function is referenced in databricks.yml and is responsible for loading
    bundle resources defined in Python code. This function is called by Databricks CLI during
    bundle deployment. After deployment, this function is not used.
    """

    # Load statically defined jobs (e.g. my_python_job)
    resources = load_resources_from_current_package_module()

    # Load dynamically generated jobs from yaml_driven_job
    yaml_resources = load_yaml_driven_jobs(bundle)
    for name, job in yaml_resources.jobs.items():
        resources.add_job(name, job)

    return resources
