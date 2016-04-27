#!/bin/bash

set -euo pipefail

IMAGE="$GO_PIPELINE_NAME-$GO_PIPELINE_COUNTER"
CONTAINER="$IMAGE-run"

docker build -t $IMAGE .

VAULT_TOKEN=$(
  docker run \
    -e VAULT_ADDR=$VAULT_ADDR \
    -e VAULT_TOKEN=$VAULT_MASTER_TOKEN \
    faraday/vault \
    ./vault token-create \
      -display-name=$CONTAINER \
      -lease=720h \
      -policy=publish-aports \
  | grep token | grep -v token_ \
  | awk '{ print $2; }'
)

docker run -t \
  -e VAULT_ADDR=$VAULT_ADDR \
  -e VAULT_TOKEN=$VAULT_TOKEN \
  -e UPLOAD_PACKAGES=1 \
  --name $CONTAINER \
  $IMAGE
  
docker rm -f $CONTAINER
docker rmi $IMAGE
