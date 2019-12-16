INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

DEPLOYMENTS=(
    "dex dex"
    "kube-system oauth2-oauth2-proxy"
    "cert-manager cert-manager"
    "cert-manager cert-manager-cainjector"
    "cert-manager cert-manager-webhook"
    "elastic-system kibana-kb"
    "harbor harbor-harbor-chartmuseum"
    "harbor harbor-harbor-clair"
    "harbor harbor-harbor-core"
    "harbor harbor-harbor-jobservice"
    "harbor harbor-harbor-notary-server"
    "harbor harbor-harbor-notary-signer"
    "harbor harbor-harbor-portal"
    "harbor harbor-harbor-registry"
    "kube-system coredns"
    "kube-system coredns-autoscaler"
    "kube-system kubernetes-dashboard"
    "kube-system kubernetes-metrics-scraper"
    "kube-system metrics-server"
    "kube-system nfs-client-provisioner"
    "nginx-ingress nginx-ingress-default-backend"
    "monitoring prometheus-operator-operator"
    "monitoring prometheus-operator-grafana"
    "monitoring prometheus-operator-kube-state-metrics"
    "influxdb-prometheus influxdb"
    "ck8sdash ck8sdash"
)

echo
echo
echo "Testing deployments"
echo "==================="

for DEPLOYMENT in "${DEPLOYMENTS[@]}"
do
    arguments=($DEPLOYMENT)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence deployment $DEPLOYMENT
    then
        testDeploymentStatus $DEPLOYMENT
    fi
done

DAEMONSETS=(
    "kube-system canal"
    "nginx-ingress nginx-ingress-controller"
    "monitoring prometheus-operator-prometheus-node-exporter"
)

echo
echo
echo "Testing daemonsets"
echo "=================="

for DAEMONSET in "${DAEMONSETS[@]}"
do
    arguments=($DAEMONSET)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence daemonset $DAEMONSET
    then
        testDaemonsetStatus $DAEMONSET
    fi
done

STATEFULSETS=(
    "monitoring prometheus-prometheus-operator-prometheus"
    "monitoring prometheus-wc-scraper-prometheus-instance"
    "monitoring alertmanager-prometheus-operator-alertmanager"
    "elastic-system elastic-operator"
    "harbor harbor-harbor-database"
    "harbor harbor-harbor-redis"
)
if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    STATEFULSETS+=("monitoring prometheus-customer-scraper-prometheus-instance")
fi

echo
echo
echo "Testing statefulsets"
echo "===================="

for STATEFULSET in "${STATEFULSETS[@]}"
do
    arguments=($STATEFULSET)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence statefulset $STATEFULSET
    then
        testStatefulsetStatus $STATEFULSET
    fi
done

echo
echo
echo "Testing other services"
echo "======================"

echo -n -e "\nelasticsearch\t"
# This checks the health status of the elasticsearch custom resource
RES=$(kubectl -n elastic-system get elasticsearches.elasticsearch.k8s.elastic.co -o jsonpath="{.items[0].status.health}")
if [[ $RES == "green" ]]
then echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
else echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
fi
