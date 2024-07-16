export INTERACTIVE=false

# The new version being defined, i.e.: 1.4.0
export NEW_VERSION="1.5.5"

# The current version to be used as a source for the new one, i.e.: 1.4.0-rc2
export CUR_VERSION="1.5.4"

# The latest released version to be replaced (non rc), i.e.: 1.3.0
export REPLACES_VERSION="1.5.4"

# The tag to be used for the skupper-router image
export SKUPPER_ROUTER_TAG="2.5.3"

# The tag to be used for the control plane images:
# site-controller, service-controller, config-sync, flow-collector
export SKUPPER_CONTROL_TAG="1.5.5"

# Comma separated list of versions to be skipped (optional)
# example:
# SKIP_VERSIONS="1.4.0-rc2,1.4.0-rc3"
#unset SKIP_VERSIONS
#export SKIP_VERSIONS="1.4.0-rc2,1.4.0-rc3"
