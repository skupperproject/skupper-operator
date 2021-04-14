# Skupper Operator

Skupper operator that simply produces the bundle and the index images.
Its goal is to avoid introducing a new CRD, just relying on the site-controller
to kick things off based on an existing skupper-site ConfigMap.

# Building the bundle and index images

To build the bundle and index images, you just need to run: `make`.

# Adding it to the catalog

If you want to test your catalog against a local minikube cluster,
you'll need to install OLM first. For more info, check this out:
https://olm.operatorframework.io/docs/getting-started/

In an OpenShift cluster, OLM is already installed. So you just need to 
create your CatalogSource.

## Minikube

TBD

## OpenShift

TBD

# Installing the operator

## Namespace installation

TBD

## Cluster-wide installation

TBD

# Creating a new skupper site

Just create a `ConfigMap` named `skupper-site` at the desired namespace.
See an example below:

```
TBD
```
