import os
import sys
import yaml
from datetime import datetime


# reading params from env vars
newversion=os.getenv("NEW_VERSION")

#
# facts to be used in the csv
#
indeximage = "quay.io/skupper/skupper-operator-index:v" + newversion
startingCSV = "skupper-operator.v" + newversion

#
# updating catalog sources
#
csfiles = ['examples/k8s/00-cs.yaml', 'examples/ocp/00-cs.yaml']
for csf in csfiles:
    # loading catalogsource (yaml) file
    with open(csf, 'r') as f:
        cs = yaml.safe_load(f)
    cs['spec']['image'] = indeximage
    # saving YAML file
    with open(csf, 'w') as f:
        yaml.dump(cs, f, default_style=False, default_flow_style=False, canonical=False, line_break=None)

#
# updating subscriptions
#
subfiles = [
    'examples/k8s/10-sub.yaml',
    'examples/ocp/10-sub.yaml'
]
for subf in subfiles:
    # loading subscription (yaml) file
    with open(subf, 'r') as f:
        sub = yaml.safe_load(f)
    sub['spec']['startingCSV'] = startingCSV
    # saving YAML file
    with open(subf, 'w') as f:
        yaml.dump(sub, f, default_style=False, default_flow_style=False, canonical=False, line_break=None)
