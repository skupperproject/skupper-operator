#!/bin/bash

. scripts/read_var.sh
. scripts/vars.sh

INTERACTIVE=${INTERACTIVE:-true}

function error() {
    echo $*
    exit 1
}

function getImageSHA() {
    IMAGE="$1"
    podman image pull ${IMAGE} > /dev/null 2>&1
    DIGEST=$(podman image inspect --format='{{.Digest}}' ${IMAGE})
    [[ $? -ne 0 ]] && exit 1
    echo "${IMAGE//:*/@${DIGEST}}"
}

if ${INTERACTIVE}; then
	echo "Skupper operator update preparation tool"
	echo "========================================"
	echo
	read_var NEW_VERSION "New skupper-operator version" true ""
	
	cur_default=`grep '^VERSION := v' Makefile | cut -c 13-`
	
	read_var CUR_VERSION "Previous CSV version" true "${cur_default}"
	read_var REPLACES_VERSION "CSV version to replace (latest released version - non rc)" true "${cur_default}"
	SKIP_VERSIONS=""
    count=0
	while true; do
        let count++
	    read_var SKIP_VERSION "Enter version(s) to be skipped (or empty when done)" false ""
	    [[ -z "${SKIP_VERSION}" ]] && break
        [[ ${count} -gt 1 ]] && SKIP_VERSIONS+=","
	    SKIP_VERSIONS+="${SKIP_VERSION}"
	done
    
	
	echo
	echo Enter image tags
	echo
	
	
	read_var SKUPPER_ROUTER_TAG "Router image tag" true ""
	read_var SKUPPER_CONTROL_TAG "Control plane images tag" true ""
	read_var PROMETHEUS_TAG "Prometheus image tag" true ""
	read_var OAUTH_PROXY_TAG "OAuth Proxy image tag" true ""
fi

errors=()
for var in ${REQUIRED_VARS[@]}; do
    val="`eval echo \\$${var}`"
    [[ -z "${val}" ]] && errors+=("${var}")
done
[[ ${#errors} -gt 0 ]] && echo "The following variables are required: ${errors[@]}" && exit 1

echo "Pulling images to determine their SHAs..."
export SKUPPER_ROUTER_SHA=`getImageSHA quay.io/skupper/skupper-router:${SKUPPER_ROUTER_TAG}`
export SITE_CONTROLLER_SHA=`getImageSHA quay.io/skupper/site-controller:${SKUPPER_CONTROL_TAG}`
export SERVICE_CONTROLLER_SHA=`getImageSHA quay.io/skupper/service-controller:${SKUPPER_CONTROL_TAG}`
export CONFIG_SYNC_SHA=`getImageSHA quay.io/skupper/config-sync:${SKUPPER_CONTROL_TAG}`
export FLOW_COLLECTOR_SHA=`getImageSHA quay.io/skupper/flow-collector:${SKUPPER_CONTROL_TAG}`
export PROMETHEUS_SHA=`getImageSHA quay.io/prometheus/prometheus:${PROMETHEUS_TAG}`
export OAUTH_PROXY_SHA=`getImageSHA quay.io/openshift/origin-oauth-proxy:${OAUTH_PROXY_TAG}`

echo
echo
echo Summary
echo
echo
printf "%-25s: %s\n" "==== Version info ===="
printf "%-25s: %s\n" "New version" "${NEW_VERSION}"
printf "%-25s: %s\n" "Previous version" "${CUR_VERSION}"
printf "%-25s: %s\n" "Replaces version" "${REPLACES_VERSION}"
printf "%-25s: %s\n" "Versions to skip" "${SKIP_VERSIONS:-none}"
echo
echo
printf "%-25s: %s\n" "==== New images ===="
printf "%-25s: %s\n" "Skupper Router SHA" "${SKUPPER_ROUTER_SHA}"
printf "%-25s: %s\n" "Site Controller SHA" "${SITE_CONTROLLER_SHA}"
printf "%-25s: %s\n" "Service Controller SHA" "${SERVICE_CONTROLLER_SHA}"
printf "%-25s: %s\n" "Config Sync SHA" "${CONFIG_SYNC_SHA}"
printf "%-25s: %s\n" "Flow Collector SHA" "${FLOW_COLLECTOR_SHA}"
printf "%-25s: %s\n" "Prometheus SHA" "${PROMETHEUS_SHA}"
printf "%-25s: %s\n" "OAuth Proxy SHA" "${OAUTH_PROXY_SHA}"
echo
echo

if ${INTERACTIVE}; then
	read_var CONTINUE "Continue?" true "yes" "yes" "no"
	[[ "${CONTINUE,,}" = "no" ]] && exit 0
	echo
	echo
fi

MAJOR_MIN_VERSION=$(echo "${NEW_VERSION}" | sed -re 's/(.*)\.[0-9]+.*/\1/g')
MAJOR_VERSION=$(echo "${MAJOR_MIN_VERSION}" | sed -re 's/(.*)\.[0-9]+/\1/g')

# Create a new CSV
function createAndPrepareCSV() {
    # Creating directory and copying CSV
    if ${INTERACTIVE} && [[ -d bundle/manifests/${NEW_VERSION} ]]; then
        echo
        read_var CONTINUE "Bundle for ${NEW_VERSION} is already defined, ovewrite?" true "no" "yes" "no"
        [[ "${CONTINUE,,}" = "no" ]] && exit 0
        echo
    fi
    rm -rf bundle/manifests/${NEW_VERSION}
    mkdir bundle/manifests/${NEW_VERSION} 
    oldcsv="bundle/manifests/${CUR_VERSION}/skupper-operator.v${CUR_VERSION}.clusterserviceversion.yaml"
    newcsv="bundle/manifests/${NEW_VERSION}/skupper-operator.v${NEW_VERSION}.clusterserviceversion.yaml"
    cp ${oldcsv} ${newcsv}

    # Updating metadata/annotations.yaml
    sed -ri "s/ (operators\.operatorframework\.io\.bundle\.channels\.v1): .*/ \1: alpha,stable,stable-${MAJOR_VERSION},stable-${MAJOR_MIN_VERSION}/g" bundle/metadata/annotations.yaml || error "Error updating channels in bundle/metadata/annotations.yaml"

    # Updating CSV file
    python ./scripts/update_csv.py ${newcsv}
}

#
# Create and update CSV file
#
createAndPrepareCSV 
#
# Updating examples
#
python ./scripts/update_examples.py
#
# Updating README.md
#
sed -i "s/skupper-operator.v${CUR_VERSION}/skupper-operator.v${NEW_VERSION}/g" README.md
#
# Updating bundle.Dockerfile
#
sed -i "s#COPY bundle/manifests/${CUR_VERSION}#COPY bundle/manifests/${NEW_VERSION}#g" bundle.Dockerfile
#
# Updating Makefile
#
sed -ri "s/^VERSION := .*/VERSION := v${NEW_VERSION}/g" Makefile

echo
cat << EOF
Bundle has been updated locally!
EOF
