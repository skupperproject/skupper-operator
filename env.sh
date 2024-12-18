export INTERACTIVE=false

# The new version being defined, i.e.: 1.4.0
export NEW_VERSION="2.1.0"

# The current version to be used as a source for the new one, i.e.: 1.4.0-rc2
export CUR_VERSION="2.0.0"

# The latest released version to be replaced (non rc), i.e.: 1.3.0
export REPLACES_VERSION="2.0.0"

# The tag to be used for the skupper-router image
# TODO: 3.1.0
export SKUPPER_ROUTER_TAG="3.1.0"

# The tag to be used for the control plane images:
# controller, kube-adaptor, network-observer
# TODO: 2.0.0
export SKUPPER_CONTROL_TAG="v2-latest"

# The tag to be used for the prometheus image
export PROMETHEUS_TAG="v2.42.0"

# The tag to be used for the oauth proxy image
export OAUTH_PROXY_TAG="4.14.0"

# Comma separated list of versions to be skipped (optional)
# example:
# SKIP_VERSIONS="1.4.0-rc2,1.4.0-rc3"
#unset SKIP_VERSIONS
#export SKIP_VERSIONS="1.4.0-rc2,1.4.0-rc3"
