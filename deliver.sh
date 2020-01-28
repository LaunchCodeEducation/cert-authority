#!/usr/bin/env bash

# -- ENV VARS -- #
BUCKET_NAME=launchcode-gisdevops-cert-authority
# -- END ENV VARS -- #

# build jar
cd cert-authority
./gradlew bootJar

# bundle files to upload
cd -
cp cert-authority/build/libs/cert-authority-0.0.1-SNAPSHOT.jar s3-data/app.jar

# upload to bucket
aws s3 sync s3-data/ "s3://${BUCKET_NAME}/"