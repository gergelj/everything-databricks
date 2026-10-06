from pyspark import pipelines as dp

from claims_logic import add_risk_band, normalize_claims


@dp.table(comment="Validated, typed claims with an SIU risk band")
@dp.expect_or_drop("has_claim_id", "claim_id IS NOT NULL")
@dp.expect_or_drop("has_policy_id", "policy_id IS NOT NULL")
@dp.expect_or_drop("positive_amount", "claim_amount_ils > 0")
@dp.expect("claim_after_policy_start", "days_since_policy_start >= 0")
def silver_claims():
    return add_risk_band(normalize_claims(spark.readStream.table("bronze_claims")))
