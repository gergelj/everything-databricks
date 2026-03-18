from pyspark import pipelines as dp


@dp.temporary_view()
def users_cdf():
    return (
        spark.readStream.option("readChangeFeed", "true")
        .table("default_catalog.default.users")
        .filter("_change_type != 'update_preimage'")
    )
