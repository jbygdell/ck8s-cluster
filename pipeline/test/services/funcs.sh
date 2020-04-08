#Args:
#   1. kind
#   2. namespace
#   3. name of resource
function testResourceExistence {
    if kubectl get $1 -n $2 $3 &> /dev/null
    then
        echo -n -e "\texists ✔"; SUCCESSES=$((SUCCESSES+1))
        return 0
    else
        echo -n -e "\tmissing ❌"; FAILURES=$((FAILURES+1))
        return 1
    fi
}

# Makes dataset smaller for optimization
#Args:
#   1. kind
function getStatus() {
    kind="${1}"
    jsonData=$(kubectl get ${kind} --all-namespaces -o json)
    lessData=$(echo ${jsonData} | 
        jq '.items[] | 
            {kind: .kind , name: .metadata.name , namespace: .metadata.namespace , 
            status: .status.readyReplicas , replicas: .status.replicas , 
            numberReady: .status.numberReady , desiredNumberScheduled: .status.desiredNumberScheduled}')
    echo "${lessData}"
}

#Args:
#   1. kind
#   2. namespace
#   3. name of resource
function testResourceExistenceFast {
    kind="${1}"
    namespace="${2}"
    currentResource="${3}"
    simpleData="${4}"
    activeResourceStatus=$(echo "${simpleData}" | 
        jq -r --arg name "${currentResource}" --arg namespace "${namespace}" --arg kind "${kind}" '. | 
            select(.name==$name and .namespace==$namespace and .kind==$kind) | 
            .status')

    echo -n "${currentResource}"
    if [[ -z "${activeResourceStatus}" ]]; then
        echo -n -e "\texists ❌"; FAILURES=$((FAILURES+1))
        echo -e "\tready ❌"; FAILURES=$((FAILURES+1))
    else
        echo -n -e "\texists ✔"
        resourceReplicaCompare "${kind}" "${namespace}" "${currentResource}" "${simpleData}"
    fi
}

# This function checks if the amount of replicas for a deployment, daemonset or statefulset are correct
#Args:
#   1. kind
#   2. namespace
#   3. name of resource
#   4. jsonData
function resourceReplicaCompare() {
    kind="${1}"
    namespace="${2}"
    resourceName="${3}"
    simpleData="${4}"
    retriesLeft=5
    while [[ "${retriesLeft}" -gt 0 ]]; do
        if [[ "${kind}" == "Deployment" || "${kind}" == "StatefulSet" ]]; then
            activeResourceStatus=$(echo "${simpleData}" | 
                jq -r --arg name "${resourceName}" --arg kind "${kind}" '. | 
                    select(.kind==$kind and .name==$name) | 
                    .status')

            desiredResourceStatus=$(echo "${simpleData}" | 
                jq -r --arg name "${resourceName}" --arg kind "${kind}" '. | 
                    select(.kind==$kind and .name==$name) | 
                    .replicas')
        # JSON data structure for daemonsets is different from deployments and statefulsets, 
        # can not check amount of replicas in the exact same way
        elif [[ "${kind}" == "DaemonSet" ]]; then
            activeResourceStatus=$(echo "${simpleData}" | 
                jq -r --arg name "${resourceName}" --arg kind "${kind}" '. | 
                    select(.kind==$kind and .name==$name) | 
                    .numberReady')

            desiredResourceStatus=$(echo "${simpleData}" | 
                jq -r --arg name "${resourceName}" --arg kind "${kind}" '. | 
                    select(.kind==$kind and .name==$name) | 
                    .desiredNumberScheduled')
        fi

        if [[ "${activeResourceStatus}" == "${desiredResourceStatus}" ]]; then
            echo -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
            return
        else
            # retry for 30s
            sleep 6
            retriesLeft=$((retriesLeft-1))
            # refresh jsonData
            simpleData="$(getStatus ${kind})"
        fi
    done

    echo -e "\tready ❌"; FAILURES=$((FAILURES+1))
    DEBUG_OUTPUT+=$(kubectl get ${kind} -n ${namespace} ${resourceName} -o json)
}

# This function is required for statefulsets with update strategy OnDelete
# since `kubectl rollout status` doesn't work for them.
#Args:
#   1. namespace
#   2. name of statefulset
function testStatefulsetStatusByPods {
    REPLICAS=$(kubectl get statefulset -n $1 $2 -o jsonpath="{.status.replicas}")

    for replica in $(seq 0 $((REPLICAS - 1))); do
        POD_NAME=$2-$replica
        if ! kubectl wait -n $1 --for=condition=ready pod $POD_NAME --timeout=60s > /dev/null; then
            echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
            DEBUG_OUTPUT+=($(kubectl get statefulset -n $1 $2 -o json))
            return
        fi
    done
    echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
}

#Args:
#   1. namespace
#   2. name of job
#   3. Wait time for job to finish before marking failed
function testJobStatus {
    kubectl wait --for=condition=complete --timeout=$3 -n $1 job/$2 > /dev/null
    if [ $? == 0 ]; then
      echo -n -e "\tcompleted ✔"; SUCCESSES=$((SUCCESSES+1))
    else
      echo -n -e "\tnot completed ❌"; FAILURES=$((FAILURES+1))
      DEBUG_OUTPUT+=($(kubectl get -n $1 job $2 -o json))
      DEBUG_LOGS+=($(kubectl logs -n $1 job/$2))
    fi
}

#Args:
#   1. Name of endpoint to print
#   2. url
#   3. (optional) username and password, <username>:<password>
function testEndpoint {
    echo -e "Testing $1 endpoint"

    retries=6
    while [ ${retries} -gt 0 ]; do
        args=(
            -ksIL
            -o /dev/null
            -X GET
            -w "%{http_code}"
        )
        [ ! -z "${3}" ] && args+=(-u "${3}")

        RES=$(curl "${args[@]}" "${2}")
        [[ $RES == "200" ]] && break

        sleep 10
        retries=$((retries-1))
    done

    if [[ $RES == "200" ]]
    then echo "success ✔"; SUCCESSES=$((SUCCESSES+1))
    else echo "failure ❌"; FAILURES=$((FAILURES+1))
    fi
}