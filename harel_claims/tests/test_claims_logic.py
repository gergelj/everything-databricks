import random
from datetime import date

import pytest

from claims_logic import add_risk_band, normalize_claims
from harel_claims.sample_data import make_claim

COLUMNS = ["claim_id", "policy_id", "line_of_business", "claim_amount_ils", "claim_date", "policy_start_date"]


@pytest.mark.parametrize(
    "amount, claim_date, expected_band",
    [
        (80_000, "2026-01-10", "HIGH"),  # high value, 9 days after start
        (80_000, "2026-06-01", "MEDIUM"),  # high value only
        (1_000, "2026-01-10", "MEDIUM"),  # early only
        (1_000, "2026-06-01", "LOW"),
    ],
)
def test_risk_band(spark, amount, claim_date, expected_band):
    df = spark.createDataFrame(
        [("c1", "POL-1", " motor ", str(amount), claim_date, "2026-01-01")], COLUMNS
    )
    row = add_risk_band(normalize_claims(df)).first()
    assert row.risk_band == expected_band
    assert row.line_of_business == "MOTOR"


def test_sample_claims_match_pipeline_schema(spark):
    rng = random.Random(42)
    claims = [make_claim(rng, date(2026, 10, 5)) for _ in range(50)]
    df = spark.createDataFrame([[c[k] for k in COLUMNS] for c in claims], COLUMNS)
    result = add_risk_band(normalize_claims(df))
    assert result.filter("days_since_policy_start < 0").count() == 0
    assert {r.risk_band for r in result.select("risk_band").collect()} <= {"LOW", "MEDIUM", "HIGH"}
