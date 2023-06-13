export SKIP_TEXT=""
if [[ -n "${SKIP_VERSIONS}" ]]; then
    SKIP_TEXT=', "skips": ['
    count=0
    for sv in ${SKIP_VERSIONS//,/ }; do
        let count++
        [[ ${count} -gt 1 ]] && SKIP_TEXT+=", "
        SKIP_TEXT+="\"skupper-operator.${sv}\""
    done
    SKIP_TEXT+=']'
fi
cat ${CATALOG_YAML} | \
    yq -y "if .entries then .entries+=[{\"name\": \"skupper-operator.${VERSION}\", \"replaces\": \"skupper-operator.${REPLACES_VERSION}\"${SKIP_TEXT}}] else . end" > ${CATALOG_YAML}.new
