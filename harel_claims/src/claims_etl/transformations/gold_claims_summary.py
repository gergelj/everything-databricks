from pyspark import pipelines as dp
from pyspark.sql import functions as F


@dp.materialized_view(comment="Daily claims KPIs by line of business and risk band")
def gold_claims_summary():
    return (
        spark.read.table("silver_claims")
        .groupBy("claim_date", "line_of_business", "risk_band")
        .agg(
            F.count("*").alias("claim_count"),
            F.sum("claim_amount_ils").alias("total_amount_ils"),
            F.avg("claim_amount_ils").alias("avg_amount_ils"),
        )
    )
