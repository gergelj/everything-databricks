from pyspark import pipelines as dp

landing_path = spark.conf.get("landing_path")


@dp.table(comment="Raw claim files ingested incrementally with Auto Loader")
def bronze_claims():
    return (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("cloudFiles.inferColumnTypes", "true")
        .load(landing_path)
    )
