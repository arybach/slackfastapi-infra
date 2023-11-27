#!/usr/bin/env python
#-*- coding: utf-8 -*-
import boto3
import os

session = boto3.session.Session()
s3 = session.client(
    service_name='s3',
    endpoint_url='https://storage.yandexcloud.net',
    aws_access_key_id=os.environ['YC_ACCESS_KEY_ID'],
    aws_secret_access_key=os.environ['YC_SECRET_ACCESS_KEY']
)

# Define the bucket name
bucket_name = "slackfastbucket"

# Path to the models directory
models_dir = "/media/groot/projects/slackfastapi/slackfastapi-master/trained_models/"

# List of models to upload
models = [
    "RanFor_Actions.joblib",
    "RanFor_Action Sports.joblib",
    "RanFor_Animals.joblib",
    "RanFor_Drone Flight.joblib",
    "RanFor_Drone View.joblib",
    "RanFor_Projects.joblib",
    "RanFor_Scenic.joblib",
    "RanFor_Sports.joblib",
    "RanFor_Streams Highlights.joblib",
    "readme.txt"
]

# Upload each model to the bucket
for model in models:
    print(f"Uploading {model}...")
    s3.upload_file(os.path.join(models_dir, model), bucket_name, f"trained_models/{model}")

print("Upload complete!")
