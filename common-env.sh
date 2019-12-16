SOURCE_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

export VAULT_ADDR=https://vault.eck.elastisys.se

export TF_VAR_dns_prefix=${ENVIRONMENT_NAME}
export TF_VAR_ssh_pub_key_file_sc=${SOURCE_PATH}/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_sc.pub
export TF_VAR_ssh_pub_key_file_wc=${SOURCE_PATH}/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_wc.pub

#
# Service settings
#

# Influx cronjob backup variables.
export INFLUX_ADDR=influxdb.influxdb-prometheus.svc:8088
export INFLUX_BACKUP_SCHEDULE="0 0 * * *"

# Domains that should be allowed to log in using OAuth
export OAUTH_ALLOWED_DOMAINS="${OAUTH_ALLOWED_DOMAINS:-example.com}"

# Alerting variables
export ALERT_TO=${ALERT_TO:-none}
# Default URL is for sending to the #ck8s-ops channel
export SLACK_API_URL=${SLACK_API_URL:-https://hooks.slack.com/services/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}

# If unset -> true
export ENABLE_PSP=${ENABLE_PSP:-true}
export ENABLE_HARBOR=${ENABLE_HARBOR:-true}
export ENABLE_OPA=${ENABLE_OPA:-true}
export ENABLE_CUSTOMER_PROMETHEUS=${ENABLE_CUSTOMER_PROMETHEUS:-false}

export CUSTOMER_NAMESPACES=${CUSTOMER_NAMESPACES:-"demo"}
export CUSTOMER_ADMIN_USERS=${CUSTOMER_ADMIN_USERS:-"admin@example.com"}

#retention variables

export KUBEAUDIT_RETENTION_SIZE=${KUBEAUDIT_RETENTION_SIZE:-50}
export KUBEAUDIT_RETENTION_AGE=${KUBEAUDIT_RETENTION_AGE:-30} 
export KUBECOMPONENTS_RETENTION_SIZE=${KUBECOMPONENTS_RETENTION_SIZE:-10} 
export KUBECOMPONENTS_RETENTION_AGE=${KUBECOMPONENTS_RETENTION_SIZE:-10} 
export KUBERNETES_RETENTION_SIZE=${KUBERNETES_RETENTION_SIZE:-50} 
export KUBERNETES_RETENTION_AGE=${KUBERNETES_RETENTION_SIZE:-30} 
export LOGS_RETENTION_SIZE=${LOGS_RETENTION_SIZE:-10} 
export LOGS_RETENTION_AGE=${LOGS_RETENTION_SIZE:-30} 
export ROLLOVER_SIZE=${ROLLOVER_SIZE:-1}
export ROLLOVER_AGE=${ROLLOVER_AGE:-1}

