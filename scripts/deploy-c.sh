#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

pushd "${SCRIPTS_PATH}/../terraform/customer/" > /dev/null

# Elastic ip for the customer cluster.
E_IP=$(terraform output c-elastic-ip)

popd > /dev/null

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

# Elastic ip for the system services cluster.
SS_E_IP=$(terraform output ss-elastic-ip)

popd > /dev/null

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -

# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml

# INGRESS

# Genereate certifiacte for ingress
openssl req -x509 -nodes -newkey rsa:4096 \
    -sha256 -keyout c-key.pem -out c-cert.pem \
    -subj "/CN=${E_IP}" -days 365

# Genereate the yaml file for deploying the ingress tls secret.
kubectl -n ingress-nginx create secret tls ingress-default-cert \
    --cert=c-cert.pem --key=c-key.pem -o yaml \
    --dry-run=true > ingress-default-cert.yaml

# Create the secret from the generated file.
kubectl	apply -f ingress-default-cert.yaml


# HELM, TILLER

mkdir -p ${SCRIPTS_PATH}/../certs/customer/kube-system/certs

${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/customer "admin1"

source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/customer/kube-system/certs admin1



# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0



# FLUENTD

# TODO: This needs to be reworked so that the password is not stored as
#       plain-text in the daemonset spec.
exit

ES_PW=$(kubectl --kubeconfig=kube_config_cluster-ss.yaml get secret quickstart-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)
#kubectl apply -f ${SCRIPTS_PATH}/../manifests/fluentd/fluentd-base.yaml --dry-run -o yaml | kubectl set env --local -f - 'FLUENT_ELASTICSEARCH_PASSWORD'=$ES_PW -o yaml > ${SCRIPTS_PATH}/../manifests/fluentd/fluentd.yaml


kubectl apply -f ${SCRIPTS_PATH}/../manifests/fluentd/sa-rbac.yaml

cat <<EOF | kubectl apply -f -

apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  template:
    metadata:
      labels:
        k8s-app: fluentd-logging
        version: v1
        kubernetes.io/cluster-service: "true"
    spec:
      hostAliases:
      - ip: "${SS_E_IP}"
        hostnames:
        - "elastic.test.super.com"
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.4.2-debian-elasticsearch-1.0
        env:
          - name: FLUENT_UID
            value: "0"
          - name:  FLUENT_ELASTICSEARCH_HOST
            value: "elastic.test.super.com"
          - name:  FLUENT_ELASTICSEARCH_PORT
            value: "443"
          - name: FLUENT_ELASTICSEARCH_SCHEME
            value: "https"
          # X-Pack Authentication
          # =====================
          - name: FLUENT_ELASTICSEARCH_USER
            value: "elastic"
          - name: FLUENT_ELASTICSEARCH_PASSWORD
            value: $ES_PW
          # Option to configure elasticsearch plugin with self signed certs
          # ================================================================
          - name: FLUENT_ELASTICSEARCH_SSL_VERIFY
            value: "false"
          - name: FLUENT_ELASTICSEARCH_SSL_VERSION
            value: "TLSv1_2"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlogjournal
          mountPath: /var/log/journal
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlogjournal
        hostPath:
          path: /var/log/journal
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
EOF

echo "User/PW for elasticsearch/kibana"
echo "User: elastic"
echo "Pw: " ${ES_PW}
