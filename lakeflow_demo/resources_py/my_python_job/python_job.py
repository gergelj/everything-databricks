from databricks.bundles.jobs import Job, Task, NotebookTask


my_pydabs_project_job = Job(
    name="my_python_job",
    tasks=[
        Task(
            task_key="notebook_task",
            notebook_task=NotebookTask(
                notebook_path="src/hello_world.ipynb",
            ),
        ),
    ],
)
