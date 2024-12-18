import os
import sys
import yaml
from datetime import datetime, timezone


# reading params from env vars
newversion=os.getenv("NEW_VERSION")
curversion=os.getenv("CUR_VERSION")
replacesversion=os.getenv("REPLACES_VERSION")
newxy=".".join(newversion.split(".")[:2])
oldxy=".".join(replacesversion.split(".")[:2])
routersha=os.getenv("SKUPPER_ROUTER_SHA")
controllersha=os.getenv("CONTROLLER_SHA")
kubeadaptorsha=os.getenv("KUBE_ADAPTOR_SHA")
networkobserversha=os.getenv("NETWORK_OBSERVER_SHA")
prometheussha=os.getenv("PROMETHEUS_SHA")
oauthproxysha=os.getenv("OAUTH_PROXY_SHA")
skipversionslist=os.getenv("SKIP_VERSIONS")
skipversions=[]
if skipversionslist and len(skipversionslist) > 0:
    skipversions = skipversionslist.split(",")

# loading CSV (yaml) file
with open(sys.argv[1], 'r') as f:
    csv = yaml.safe_load(f)

#
# facts to be used in the csv
#
replacesname = "skupper-operator.v" + replacesversion
csvname = csv['metadata']['name'].replace(curversion, newversion)

# update csv name
csv['metadata']['name'] = csvname

# updating bundle image version
csv['metadata']['annotations']['createdAt'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
csv['metadata']['annotations']['containerImage'] = controllersha
try:
    del(csv['metadata']['annotations']['olm.skipRange'])
except:
    pass
if newxy != oldxy:
    csv['metadata']['annotations']['olm.skipRange'] = ">%s <%s" %(replacesversion, newversion)

# spec version
csv['spec']['version'] = newversion

# updating controller container image
csv['spec']['install']['spec']['deployments'][0]['spec']['template']['spec']['containers'][0]['image'] = controllersha

# updating images for environment variables
for envvar in csv['spec']['install']['spec']['deployments'][0]['spec']['template']['spec']['containers'][0]['env']:
    if envvar['name'] == "QDROUTERD_IMAGE":
        envvar['value'] = routersha
    elif envvar['name'] == "SKUPPER_CONTROLLER_IMAGE":
        envvar['value'] = controllersha
    elif envvar['name'] == "SKUPPER_KUBE_ADAPTOR_IMAGE":
        envvar['value'] = kubeadaptorsha
    elif envvar['name'] == "SKUPPER_NETWORK_OBSERVER_IMAGE":
        envvar['value'] = networkobserversha
    elif envvar['name'] == "PROMETHEUS_SERVER_IMAGE":
        envvar['value'] = prometheussha
    elif envvar['name'] == "OAUTH_PROXY_IMAGE":
        envvar['value'] = oauthproxysha

# updating related images section
csv['spec']['relatedImages'] = [{
    'name': 'skupper-controller',
    'image': controllersha,
}, {
    'name': 'skupper-router',
    'image': routersha,
}, {
    'name': 'skupper-kube-adaptor',
    'image': kubeadaptorsha,
}, {
    'name': 'skupper-network-observer',
    'image': networkobserversha,
}, {
    'name': 'ose-prometheus',
    'image': prometheussha,
}, {
    'name': 'ose-oauth-proxy',
    'image': oauthproxysha,
}]

# updating spec replaces value
csv['spec']['replaces'] = replacesname

# adding skipped versions (if any)
if len(skipversions) > 0:
    if not 'skips' in csv['spec']:
        csv['spec']['skips'] = []
    for ver in skipversions:
        skipname = csvname.replace(newversion, ver)
        csv['spec']['skips'].append(skipname)

#
# literal_unicode and literal_unicode_presenter are used to render
# blocks using | literal
#
class literal_unicode(str): pass

def literal_unicode_representer(dumper, data):
    return dumper.represent_scalar(u'tag:yaml.org,2002:str', data, style='|')

yaml.add_representer(literal_unicode, literal_unicode_representer)

# rendering description using literal block
csv['spec']['description'] = literal_unicode(csv['spec']['description'])

# saving YAML file
with open(sys.argv[1], 'w') as f:
    yaml.dump(csv, f, default_style=False, default_flow_style=False, canonical=False, line_break=None)
