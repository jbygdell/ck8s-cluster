#!/bin/bash

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
pushd "${SCRIPTS_PATH}/../" > /dev/null

export ECK_BASE_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name')
export ECK_OPS_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name' | sed 's/^/ops./')

popd > /dev/null

export S3_ACCESS_KEY=$EXOSCALE_API_KEY
export S3_SECRET_KEY=$EXOSCALE_SECRET_KEY
export S3_REGION=ch-gva-2
export S3_REGION_ENDPOINT=https://sos-ch-gva-2.exo.io
export S3_HARBOR_BUCKET_NAME=harbor
export S3_VELERO_BUCKET_NAME=velero
export S3_ES_BACKUP_BUCKET_NAME=es-backup
# Influx backup variables
export INFLUX_ADDR=influx.influxdb-prometheus.svc:8088
export S3_INFLUX_BUCKET_URL=s3://influxdb-backups
export INFLUX_BACKUP_SCHEDULE="0 0 * * *"

# Disable alerts
export ALERT_TO=none
# In case we want alerts at some point
export SLACK_API_URL=https://hooks.slack.com/services/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

export ENABLE_PSP=true
export ENABLE_OPA=true
export ENABLE_HARBOR=true
export ENABLE_CUSTOMER_PROMETHEUS=false
export OAUTH_ALLOWED_DOMAINS="example.com"
export CUSTOMER_NAMESPACES="demo"
export CUSTOMER_ADMIN_USERS="admin@example.com"

export KUBEAUDIT_RETENTION_SIZE=50 #SIZE in GB when auditlogs should be removed or 'kubeaudit'
export KUBEAUDIT_RETENTION_AGE=30 #AGE in days when auditlogs should be removed or 'kubeaudit'
export KUBECOMPONENTS_RETENTION_SIZE=10 #SIZE in GB when api-server logs should be removed or 'kubecomponents'
export KUBECOMPONENTS_RETENTION_AGE=10 #AGE in days when api-server logs should be removed or 'kubecomponents'
export KUBERNETES_RETENTION_SIZE=50 #SIZE in GB when kubernetes container logs should be removed or 'kubernetes'
export KUBERNETES_RETENTION_AGE=30 #AGE in days when kubernetes container  logs should be removed or 'kubernetes'
export OTHER_RETENTION_SIZE=1 #SIZE in GB when other logs should be removed for index 'other'
export OTHER_RETENTION_AGE=10 #AGE in days when other logs should be removed for index 'other'
export ROLLOVER_SIZE=1 #SIZE in GB when indices should perform rollover
export ROLLOVER_AGE=1 #AGE in days when indices should perform rollover
