set -euo pipefail

echo
echo "IMPORTANT"
echo "Make sure you have sourced env.sh from correct branch of the skupper-operator repository"
echo 

BRANCH=$(echo "${NEW_VERSION}" | sed -re 's/(.*)\.[0-9]+.*/\1/g')
 
FAIL=0
git remote -v > /dev/null 2>&1 | grep -Eq '/community-operators(-prod)*.git' || FAIL=1FAIL=1
if [[ $? -ne 0 ]] || [[ ! -d .git/ ]]; then
    echo "You must run this script inside your fork of the Operator Hub or Community Operators repository's root dir"
    echo "Operator Hub       : https://github.com/k8s-operatorhub/community-operators.git"
    echo "Community Operators: https://github.com/redhat-openshift-ecosystem/community-operators-prod.git"
    exit 1
fi

REPODIR=`pwd`
cd ./operators/skupper-operator
mkdir ${NEW_VERSION}
cd ${NEW_VERSION}

mkdir manifests metadata

cd manifests
wget https://raw.githubusercontent.com/skupperproject/skupper-operator/${BRANCH}/bundle/manifests/${NEW_VERSION}/skupper-operator.v${NEW_VERSION}.clusterserviceversion.yaml
cd ../
cd metadata
wget https://raw.githubusercontent.com/skupperproject/skupper-operator/${BRANCH}/bundle/metadata/annotations.yaml

cd ${REPODIR}

echo
echo "Now commit your changes and make sure to sign your commit,"
echo "otherwise the PR will be rejected."
echo
echo "Open the PR and fill in the template."
