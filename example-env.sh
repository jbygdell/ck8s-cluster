export ENVIRONMENT_NAME=test
export CERT_TYPE="<staging|prod>"

#
# Infrastructure
#

export TF_VAR_sc_master_count=number # default 1
export TF_VAR_wc_master_count=number # default 1
export TF_VAR_sc_worker_count=number # default 1
export TF_VAR_wc_worker_count=number # default 1

# The AWS credentials are only needed if you don't have them in ~/.aws/credentials
export AWS_ACCESS_KEY_ID=12345abcde
export AWS_SECRET_ACCESS_KEY=somelongsecret

# S3 buckets
export S3_ACCESS_KEY=12345abcde
export S3_SECRET_KEY=somelongsecret
export S3COMMAND_CONFIG_FILE=.s3cfg_${ENVIRONMENT_NAME}
export S3_HARBOR_BUCKET_NAME=harbor-bucket-name
export S3_VELERO_BUCKET_NAME=velero-bucket-name
export S3_ES_BACKUP_BUCKET_NAME=es-backup-name
export S3_INFLUX_BUCKET_NAME=influxdb-bucket-name
export S3_SC_FLUENTD_BUCKET_NAME=sc-logs

# Note: You should just specify variables for ONE cloud provider!
# Comment out the rest or delete them.

#
# Exoscale
#

export CLOUD_PROVIDER=exoscale

# Machine sizes
export TF_VAR_sc_master_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_wc_master_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_sc_nfs_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_wc_nfs_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_sc_worker_size="<Small|Medium|Large|Extra-large>" # default "Extra-large"
export TF_VAR_wc_worker_size="<Small|Medium|Large|Extra-large>" # default "Large"

export TF_VAR_exoscale_api_key=12345abcde
export TF_VAR_exoscale_secret_key=somelongsecret

#
# Safespring
#

export CLOUD_PROVIDER=safespring

export OS_USERNAME=user.name@elastisys.com
export OS_PASSWORD=somelongsecret

# Optional. if left unchecked these will be set to default values in safespring-common-env
export OS_PROJECT_DOMAIN_NAME=elastisys.se
export OS_USER_DOMAIN_NAME=elastisys.se
export OS_PROJECT_NAME=infra.elastisys.se
export OS_PROJECT_ID=9f91e56185fb4f929c36430ac4bcbe6e
export S3_REGION_ENDPOINT=https://s3.sto1.safedc.net

#
# Kubernetes
#

# Rancher kubernetes image to use.
export KUBERNETES_VERSION="<rancher image>" # default '"v1.15.6-rancher1-2"'

#
# Services
#

export ENABLE_HARBOR="<true|false>" # default true
export ENABLE_FALCO="<true|false>" # default true
export ENABLE_PSP="<true|false>" # default true
export ENABLE_OPA="<true|false>" # default true
export ENABLE_CUSTOMER_GRAFANA="<true|false>" # default true
export ENABLE_CUSTOMER_ALERTMANAGER="<true|false>" # default false
export ENABLE_CUSTOMER_ALERTMANAGER_INGRESS="<true|false>" # default false
export ENABLE_POSTGRESQL="<true|false>" # default false

# Identity providers
export AAA_CLIENT_ID=1234
export AAA_CLIENT_SECRET=somelongsecret
export GOOGLE_CLIENT_ID=1234512345abcdeabcde.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=somelongsecret

# Only emails with these domains are allowed to login through dex.
# Applies to Google as identity provider and Grafana oauth login.
export OAUTH_ALLOWED_DOMAINS="example.com elastisys.com" # default "example.com"

# Customer access
export CUSTOMER_NAMESPACES="demo1 demo2 demo3" # default "demo"
export CUSTOMER_ADMIN_USERS="admin1@example.com admin2@example.com" # default "admin@example.com"

# Create a static dex user "admin@example.com"
export ENABLE_STATIC_DEX_LOGIN="<true|false>" # default false
# Dex static user password bcrypt hash (generate e.g. here https://bcrypt-generator.com/)
export DEX_STATIC_PWD='$2y$12$uHfoo.raWolRAisWPBIQM.kzioR2voTrDkM7JmfasJnRGVDpgbyja' # default hash of "password"

# Passwords for services
# If you are using vault, you should not set these, they will be set by `get-gen-secrets.sh` instead.
export GRAFANA_PWD=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export HARBOR_PWD=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export INFLUXDB_PWD=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export KUBELOGIN_CLIENT_SECRET=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export GRAFANA_CLIENT_SECRET=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export CUSTOMER_PROMETHEUS_PWD=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export CUSTOMER_GRAFANA_PWD=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export CUSTOMER_ALERTMANAGER_PWD=somelongsecret # default randomly generated by `get-gen-secrets.sh`
export ELASTIC_USER_SECRET=z4lcf527wqv2np8n2wcqtqxs #default randomly generated by  `get-gen-secrets.sh`

# Alerting variables
export ALERT_TO="null" # default "null", one of opsgenie, slack or null
export SLACK_API_URL="https://..." # Default URL is for sending to the #ck8s-ops channel
export ENABLE_HEARTBEAT="<true|false>" # default false, use opsgenie heartbeat feature
# See https://elastisys.app.eu.opsgenie.com/settings/integration/configured-integrations
export OPSGENIE_API_KEY=api-key-here # defaults to API key for prometheus/alertmanager integration
export OPSGENIE_HEARTBEAT_NAME=name-of-heartbeat # required if heartbeat enabled, no default

# Retention variables
export KUBEAUDIT_RETENTION_SIZE=100 #SIZE in GB when auditlogs should be removed for index 'kubeaudit'
export KUBEAUDIT_RETENTION_AGE=30 #AGE in days when auditlogs should be removed for index 'kubeaudit'
export KUBECOMPONENTS_RETENTION_SIZE=1 #SIZE in GB when api-server logs should be removed for index 'kubecomponents'
export KUBECOMPONENTS_RETENTION_AGE=10 #AGE in days when api-server logs should be removed for index 'kubecomponents'
export KUBERNETES_RETENTION_SIZE=1 #SIZE in GB when kubernetes container logs should be removed for index 'kubernetes'
export KUBERNETES_RETENTION_AGE=10 #AGE in days when kubernetes container  logs should be removed for index 'kubernetes'
export OTHER_RETENTION_SIZE=1 #SIZE in GB when other logs should be removed for index 'other'
export OTHER_RETENTION_AGE=10 #AGE in days when other logs should be removed for index 'other'
export POSTGRESQL_RETENTION_SIZE=30 #SIZE in GB when other logs should be removed for index 'postgresql'
export POSTGRESQL_RETENTION_AGE=30 #AGE in days when other logs should be removed for index 'postgresql'
export ROLLOVER_SIZE=1 #SIZE in GB when indices should perform rollover
export ROLLOVER_AGE=1 #AGE in days when indices should perform rollover

export INFLUXDB_RETENTION_WC=7d # Retention policy for influxdb workload cluster database
export INFLUXDB_RETENTION_SC=7d # Retention policy for influxdb service cluster database

export PROMETHEUS_RETENTION_WC=3d # Time-based retention policy for Prometheus workload cluster database
export PROMETHEUS_STORAGE_SIZE_WC="5Gi"
export PROMETHEUS_RETENTION_SIZE_WC="4GiB" # Size-based retention policy for Prometheus workload cluster database

export PROMETHEUS_RETENTION_SC=3d # Time-based retention policy for Prometheus service cluster database
export PROMETHEUS_STORAGE_SIZE_SC="5Gi"
export PROMETHEUS_RETENTION_SIZE_SC="4GiB" # Size-based retention policy for Prometheus service cluster database

export ALERTMANAGER_RETENTION=72h # Time-based retention policy for Alertmanager
