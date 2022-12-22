#!/bin/bash

#build docker image
cd app
docker build --platform linux/amd64 -t gcp/my-app .
cd ..

#authenticate and push image to artifact repository in gcp

gcloud auth activate-service-account  --key-file=$1

gcloud auth configure-docker $2-docker.pkg.dev

docker tag gcp/my-app $2-docker.pkg.dev/$3/$4/app-image:tag1

docker push $2-docker.pkg.dev/$3/$4/app-image:tag1