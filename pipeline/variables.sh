#!/bin/bash

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
pushd "${SCRIPTS_PATH}/../" > /dev/null

export ECK_BASE_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name')
export ECK_OPS_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name' | sed 's/^/ops./')
source common-env.sh

popd > /dev/null

export S3_ACCESS_KEY=$EXOSCALE_API_KEY
export S3_SECRET_KEY=$EXOSCALE_SECRET_KEY
export S3_REGION=ch-gva-2
export S3_REGION_ENDPOINT=https://sos-ch-gva-2.exo.io
export S3_HARBOR_BUCKET_NAME=harbor
export S3_VELERO_BUCKET_NAME=velero
export S3_ES_BACKUP_BUCKET_NAME=es-backup
# Influx backup variables
export S3_INFLUX_BUCKET_URL=s3://influxdb-backups

# Disable alerts
export ALERT_TO=null
# In case we want alerts at some point
export SLACK_API_URL=https://hooks.slack.com/services/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

export OAUTH_ALLOWED_DOMAINS="example.com"
