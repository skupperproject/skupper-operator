cat ${CATALOG_YAML} | \
    yq --arg version "${VERSION}" -y 'del(. | select(.name == "skupper-operator." + $version)) | del(.entries[]? | select(.name == "skupper-operator." + $version))' \
        | sed -re '/^(--- null|\.\.\.)$$/d' > catalog.yaml.tmp && mv catalog.yaml.tmp ${CATALOG_YAML}
