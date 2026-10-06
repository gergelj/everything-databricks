"""Business rules for claims, kept as plain DataFrame -> DataFrame functions.

Pipeline files import this module (root_path is on sys.path), and the unit tests
in tests/ exercise it with a local SparkSession — no workspace needed in CI.
"""

from pyspark.sql import DataFrame
from pyspark.sql import functions as F

HIGH_VALUE_THRESHOLD_ILS = 50_000
EARLY_CLAIM_DAYS = 30


def normalize_claims(df: DataFrame) -> DataFrame:
    """Standardize types and derive claim age relative to policy start."""
    return (
        df.withColumn("claim_amount_ils", F.col("claim_amount_ils").cast("decimal(12,2)"))
        .withColumn("claim_date", F.to_date("claim_date"))
        .withColumn("policy_start_date", F.to_date("policy_start_date"))
        .withColumn("line_of_business", F.upper(F.trim("line_of_business")))
        .withColumn("days_since_policy_start", F.datediff("claim_date", "policy_start_date"))
    )


def add_risk_band(df: DataFrame) -> DataFrame:
    """Flag claims for the SIU (fraud) review queue.

    HIGH   - high value AND filed shortly after the policy started
    MEDIUM - either condition alone
    LOW    - neither
    """
    high_value = F.col("claim_amount_ils") >= HIGH_VALUE_THRESHOLD_ILS
    early = F.col("days_since_policy_start") < EARLY_CLAIM_DAYS
    return df.withColumn(
        "risk_band",
        F.when(high_value & early, "HIGH").when(high_value | early, "MEDIUM").otherwise("LOW"),
    )
