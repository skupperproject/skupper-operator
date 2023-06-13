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
    podman image inspect --format='{{index .RepoDigests 0}}' ${IMAGE} || exit 1
}

if ${INTERACTIVE}; then
	echo "Skupper operator update preparation tool"
	echo "========================================"
	echo
	read_var NEW_VERSION "New skupper-operator version" true ""
	
	cur_default=`grep '^VERSION ?= v' Makefile | cut -c 13-`
	rep_default=`grep '^REPLACES_VERSION ?= v' Makefile | cut -c 22-`
	
	read_var CUR_VERSION "Previous CSV version" true "${cur_default}"
	read_var REPLACES_VERSION "CSV version to replace (latest released version - non rc)" true "${rep_default}"
	SKIP_VERSIONS=()
	while true; do
	    read_var SKIP_VERSION "Enter version(s) to be skipped (or empty when done)" false ""
	    [[ -z "${SKIP_VERSION}" ]] && break
	    SKIP_VERSIONS+=("${SKIP_VERSION}")
	done
	
	echo
	echo Enter image tags
	echo
	
	
	read_var SKUPPER_ROUTER_TAG "Router image tag" true ""
	read_var SKUPPER_CONTROL_TAG "Control plane images tag" true ""
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
echo
echo

if ${INTERACTIVE}; then
	read_var CONTINUE "Continue?" true "yes" "yes" "no"
	[[ "${CONTINUE,,}" = "no" ]] && exit 0
	echo
	echo
fi

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

    # Updating CSV file
    python ./scripts/updatecsv.py ${newcsv}
}

#
# Create and update CSV file
#
createAndPrepareCSV 
#
# Updating examples
#
python ./scripts/updateexamples.py
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
sed -ri "s/^VERSION \?= .*/VERSION ?= v${NEW_VERSION}/g" Makefile
sed -ri "s/^REPLACES_VERSION \?= .*/REPLACES_VERSION ?= v${REPLACES_VERSION}/g" Makefile

echo
cat << EOF
Bundle has been updated locally!

Commit your changes and open a PR.
Once PR is approved and merged, you have to:

- Tag repo using the published version, in example: ${NEW_VERSION}
- Build and publish bundle using: make
EOF
