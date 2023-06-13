import os
import sys
import yaml
from datetime import datetime


# reading params from env vars
new_version=os.getenv("NEW_VERSION")
replaces_version=os.getenv("REPLACES_VERSION")

# defining env based variables
new_version_name='skupper-operator.v' + new_version
replaces_name = "skupper-operator.v" + replaces_version
skip_versions=[]
if skipversionslist and len(skipversionslist) > 0:
    for sv in skipversionslist.split(","):
        skipversions.append('skupper-operator.v' + sv)

# loading catalog (yaml) file
new_catalog_docs=list()
with open(sys.argv[1], 'r') as f:
    catalog_docs = yaml.safe_load_all(f)

    for doc in catalog_docs:
        # remove (if any) and add a new entry for new version
        if doc['schema'] == 'olm.channel':
            entries = doc['entries']
            new_entries = []
            for entry in entries:
                print(entry['name'])
                if entry['name'] != new_version_name:
                    new_entries.append(entry)
            new_entry = {
                'name': new_version_name,
                'replaces': replaces_name,
            }
            if len(skip_versions) > 0:
                new_entry['skips'] = skip_versions

            doc['entries'] = new_entries

        if doc['schema'] == 'olm.bundle' and doc['name'] == new_version_name:
            continue

        new_catalog_docs.append(doc)

with open(sys.argv[1], 'w') as f:
    yaml.dump_all(new_catalog_docs, f, default_style=False, default_flow_style=False, canonical=False, line_break=None)
