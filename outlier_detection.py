#!/usr/bin/env python
# coding: utf-8

# In[ ]:


from pyspark.sql import SparkSession
from pyspark.sql.functions import col, stddev, mean
from pyspark.sql.types import IntegerType, DoubleType

# Initialize a Spark session
spark = SparkSession.builder.appName("OutlierDetection").getOrCreate()

# Load your CSV dataset
dataset = spark.read.csv("gs://train-data-9923/train.csv", header=True, inferSchema=True)

# Identify the numerical columns in the dataset
numerical_columns = [col_name for col_name, data_type in dataset.dtypes if data_type in (IntegerType(), DoubleType())]

if not numerical_columns:
    raise ValueError("No numerical columns found in the dataset.")

# Specify the target numerical column for outlier detection (choose one)
target_column = numerical_columns[0]  # You can change this to select a different numerical column

# Calculate the mean and standard deviation for the target column
agg_stats = dataset.agg(mean(col(target_column)).alias("mean"), stddev(col(target_column)).alias("stddev")).collect()
mean_value = agg_stats[0]["mean"]
stddev_value = agg_stats[0]["stddev"]

# Define a Z-score threshold (e.g., 2.0 for a 95% confidence interval)
z_score_threshold = 2.0

# Detect outliers by calculating the Z-score for each data point in the target column
outliers = dataset.withColumn("z_score", (col(target_column) - mean_value) / stddev_value).filter(abs(col("z_score")) > z_score_threshold)

# Show the outliers
outliers.show()

# Save the outliers to a new CSV file if needed
outliers.write.csv("gs://your-bucket-name/outliers.csv", header=True, mode="overwrite")

# Stop the Spark session
spark.stop()

