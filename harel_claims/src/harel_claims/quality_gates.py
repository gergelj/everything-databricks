"""Post-pipeline quality gates. A failing gate fails the job (and the CI integration run)."""

import argparse

from pyspark.sql import SparkSession


def run_gates(spark: SparkSession, catalog: str, schema: str) -> list[str]:
    fq = f"`{catalog}`.`{schema}`"
    failures = []

    silver_rows = spark.table(f"{fq}.silver_claims").count()
    if silver_rows == 0:
        failures.append("silver_claims is empty")

    dupes = spark.sql(
        f"SELECT claim_id FROM {fq}.silver_claims GROUP BY claim_id HAVING count(*) > 1"
    ).count()
    if dupes:
        failures.append(f"{dupes} duplicate claim_id values in silver_claims")

    bad_bands = spark.sql(
        f"SELECT 1 FROM {fq}.gold_claims_summary WHERE risk_band NOT IN ('LOW','MEDIUM','HIGH')"
    ).count()
    if bad_bands:
        failures.append("unexpected risk_band values in gold_claims_summary")

    return failures


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    failures = run_gates(spark, args.catalog, args.schema)
    if failures:
        raise SystemExit("Quality gates failed:\n  - " + "\n  - ".join(failures))
    print("All quality gates passed")
