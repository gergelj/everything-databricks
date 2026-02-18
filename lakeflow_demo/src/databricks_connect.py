from databricks.connect import DatabricksSession

#spark = DatabricksSession.builder.clusterId("0205-121240-19c78nn6").getOrCreate()
spark = DatabricksSession.builder.getOrCreate()


df = spark.range(10)
df.show()