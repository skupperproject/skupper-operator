# Variables that are considered required when interactive mode is false
REQUIRED_VARS=(NEW_VERSION CUR_VERSION SKUPPER_ROUTER_TAG SKUPPER_CONTROL_TAG)

# The new version being defined, i.e.: 1.4.0
export NEW_VERSION="${NEW_VERSION:-}"
# The current version to be replaced, i.e.: 1.3.0
export CUR_VERSION="${CUR_VERSION:-}"
# The tag to be used for the skupper-router image
export SKUPPER_ROUTER_TAG="${SKUPPER_ROUTER_TAG:-}"
# The tag to be used for the control plane images:
# site-controller, service-controller, config-sync, flow-collector
export SKUPPER_CONTROL_TAG="${SKUPPER_CONTROL_TAG:-}"
# Comma separated list of versions to be skipped (optional)
# example:
# SKIP_VERSIONS="1.4.0-rc2,1.4.0-rc3"
if [[ ${#SKIP_VERSIONS} -eq 0 ]]; then
    export SKIP_VERSIONS=""
fi
