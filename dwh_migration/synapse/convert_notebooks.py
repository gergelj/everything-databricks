"""
Convert Synapse notebooks to Python scripts (.py).

Supports both:
  - Standard Jupyter notebooks (.ipynb)         -> cells at nb["cells"]
  - Synapse notebook exports (.json)            -> cells at nb["properties"]["cells"]

Usage:
  python convert_notebooks.py [input_dir] [output_dir]

If input_dir is omitted, the current working directory is used.
If output_dir is omitted, the .py files are written next to their source.
"""

import json
import os
import glob
import sys


def get_cells(nb):
    """Return the list of cells, handling both Jupyter and Synapse layouts."""
    if "cells" in nb:
        return nb["cells"]
    # Synapse notebooks nest everything under "properties"
    return (nb.get("properties") or {}).get("cells", [])


def convert_notebook(nb_path, output_dir=None):
    with open(nb_path) as f:
        nb = json.load(f)

    base, _ = os.path.splitext(os.path.basename(nb_path))
    if output_dir is None:
        py_path = os.path.join(os.path.dirname(nb_path), base + ".py")
    else:
        py_path = os.path.join(output_dir, base + ".py")
    with open(py_path, "w") as out:
        for cell in get_cells(nb):
            if cell["cell_type"] == "code":
                # Synapse code cells are already Python/PySpark, so write them
                # out verbatim. (SparkSQL cells still get wrapped.)
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
    input_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None

    notebooks = glob.glob(os.path.join(input_dir, "*.ipynb")) + glob.glob(
        os.path.join(input_dir, "*.json")
    )
    if not notebooks:
        print(f"No .ipynb or .json files found in {input_dir}")
        sys.exit(1)

    if output_dir is not None:
        os.makedirs(output_dir, exist_ok=True)

    for nb_path in notebooks:
        convert_notebook(nb_path, output_dir)
