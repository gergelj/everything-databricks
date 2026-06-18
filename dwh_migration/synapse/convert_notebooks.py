"""
Convert Jupyter notebooks (.ipynb) to Python scripts (.py).
Usage:
  python convert_notebooks.py [target_dir]

If no target_dir is specified, the current working directory is used
"""

import json
import os
import glob
import sys


def convert_notebook(nb_path):
    with open(nb_path) as f:
        nb = json.load(f)

    py_path = nb_path.replace(".ipynb", ".py")
    with open(py_path, "w") as out:
        for cell in nb.get("cells", []):
            if cell["cell_type"] == "code":
                language = ((cell.get("metadata") or {}).get("microsoft") or {}).get("language", "")
                if language == "sparksql":
                    print(f"\tSQL code found in {nb_path}")
                    sql_code = "".join(cell["source"][1:]).strip()
                    out.write("spark.sql(\"\"\"" + sql_code + "\"\"\")")
                else:
                    out.write("".join(cell["source"]))
                out.write("\n\n")
            elif cell["cell_type"] == "markdown":
                for line in cell["source"]:
                    out.write("# " + line)
                out.write("\n\n")

    print(f"Converted: {os.path.basename(nb_path)} -> {os.path.basename(py_path)}")


if __name__ == "__main__":
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    notebooks = glob.glob(os.path.join(target_dir, "*.ipynb"))
    if not notebooks:
        print(f"No .ipynb files found in {target_dir}")
        sys.exit(1)
    for nb_path in notebooks:
        convert_notebook(nb_path)