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


# Cell magics that override the notebook default language, mapped to a
# normalized language name. Databricks/Synapse also express these via
# cell.metadata.microsoft.language ("sparksql" / "python").
_MAGIC_LANGUAGES = {
    "%%sql": "sql",
    "%sql": "sql",
    "%%pyspark": "python",
    "%%python": "python",
    "%python": "python",
    "%%spark": "python",
}


def get_cells(nb):
    """Return the list of cells, handling both Jupyter and Synapse layouts."""
    if "cells" in nb:
        return nb["cells"]
    # Synapse notebooks nest everything under "properties"
    return (nb.get("properties") or {}).get("cells", [])


def get_notebook_metadata(nb):
    """Return the notebook-level metadata for Jupyter or Synapse layouts."""
    if "metadata" in nb:
        return nb["metadata"] or {}
    return (nb.get("properties") or {}).get("metadata") or {}


def get_default_language(nb):
    """The notebook-wide default language (used when a cell has no override)."""
    meta = get_notebook_metadata(nb)
    lang = (meta.get("language_info") or {}).get("name") \
        or (meta.get("kernelspec") or {}).get("language") \
        or "python"
    return "sql" if lang.lower() in ("sql", "sparksql") else lang.lower()


def classify_cell(cell, default_language):
    """Resolve a code cell's language and return (language, body).

    `body` has any language-marker magic line stripped. Precedence:
      1. Databricks/Synapse per-cell override (cell.metadata.microsoft.language)
      2. Jupyter cell/line magic on the first source line (%%sql, %%pyspark, ...)
      3. The notebook-wide default language
    """
    source = cell.get("source") or []

    # 1. Per-cell metadata override (Databricks/Synapse).
    ms_language = ((cell.get("metadata") or {}).get("microsoft") or {}).get("language")
    if ms_language:
        lang = "sql" if ms_language.lower() == "sparksql" else ms_language.lower()
        # The source may still carry a leading magic mirroring the override.
        body = source[1:] if _leading_magic(source) else source
        return lang, "".join(body).strip()

    # 2. Jupyter magic on the first line.
    magic = _leading_magic(source)
    if magic is not None:
        return _MAGIC_LANGUAGES[magic], "".join(source[1:]).strip()

    # 3. Fall back to the notebook default.
    return default_language, "".join(source).strip()


def _leading_magic(source):
    """Return the recognized magic on the first source line, or None."""
    first = source[0].strip() if source else ""
    for magic in _MAGIC_LANGUAGES:
        # Match the token exactly or as "%%sql\n..." / "%%sql SELECT ...".
        if first == magic or first.startswith(magic + " ") or first.startswith(magic + "\n"):
            return magic
    return None


def convert_notebook(nb_path, output_dir=None):
    with open(nb_path) as f:
        nb = json.load(f)

    default_language = get_default_language(nb)

    base, _ = os.path.splitext(os.path.basename(nb_path))
    if output_dir is None:
        py_path = os.path.join(os.path.dirname(nb_path), base + ".py")
    else:
        py_path = os.path.join(output_dir, base + ".py")
    with open(py_path, "w") as out:
        print(f"Converting: {os.path.basename(nb_path)} -> {os.path.basename(py_path)}")
        for cell in get_cells(nb):
            if cell["cell_type"] == "code":
                # SQL cells get wrapped in spark.sql(...); Python cells are
                # written out verbatim (with any language magic stripped).
                language, body = classify_cell(cell, default_language)
                if language == "sql":
                    out.write("spark.sql(\"\"\"" + body + "\"\"\")")
                else:
                    out.write(body)
                out.write("\n\n")
            elif cell["cell_type"] == "markdown":
                for line in cell["source"]:
                    out.write("# " + line)
                out.write("\n\n")


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
