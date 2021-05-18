# Skupper Operator

Skupper operator that simply produces the bundle and the index images.
Its goal is to avoid introducing a new CRD, just relying on the site-controller
to kick things off based on an existing skupper-site ConfigMap.

# Installing the skupper-operator


The instructions below demonstrates how to install the skupper-operator
and run it inside the `default` namespace. If you want to install it in
a different namespace, edit the referenced yaml before applying.

If you want to test your catalog against a local minikube cluster,
you'll need to install OLM first. For more info, check this out:
https://olm.operatorframework.io/docs/getting-started/

In an OpenShift cluster, OLM is already installed. So you just need to 
create your CatalogSource.


## Installing on Minikube

To install the CatalogSource in your Minikube cluster, assuming  that
the OLM is installed (0.17.0+), run:

```
# Creating a CatalogSource at the olm namespace
kubectl apply -f examples/k8s/00-cs.yaml

# Wait for the skupper-operator catalog pod to be running
kubectl -n olm get pods | grep skupper-operator

# Create an OperatorGroup at the default namespace
kubectl apply -f examples/k8s/10-og.yaml

# Create a Subscription at the default namespace
kubectl apply -f examples/k8s/20-sub.yaml
```

## Installing on OpenShift

```
# Creating a CatalogSource at the openshift-marketplace namespace
kubectl apply -f examples/ocp/00-cs.yaml

# Wait for the skupper-operator catalog pod to be running
kubectl -n openshift-marketplace get pods | grep skupper-operator

# Create an OperatorGroup at the default namespace
kubectl apply -f examples/ocp/10-og.yaml

# Create a Subscription at the default namespace
kubectl apply -f examples/ocp/20-sub.yaml
```

## Validate skupper-operator is running

Look at the pods running at your `default` namespace now. You should 
see a running pod for the `skupper-site-controller`.

```
kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
skupper-site-controller-d7b57964-gxms6   1/1     Running   0          39m
```

At this point, the Skupper Operator is running and it will manage your
Skupper site by watching a `ConfigMap` named exclusively `skupper-site`
at the namespace where it is running (in this case the `default` namespace).

# Creating a new skupper site

Create a `ConfigMap` named `skupper-site` at the default namespace:

```
kubectl apply -f examples/skupper-site-interior.yaml
```

Once the `ConfigMap` is created, Skupper Site Controller will initialize
your Skupper site and you can verify everything is running properly if you
see the `skupper-router` and the `skupper-service-controller` pods running
at the `default` namespace, in example:

```
kubectl get pods
NAME                                          READY   STATUS    RESTARTS   AGE
skupper-router-8c6cc6d76-27562                1/1     Running   0          40s
skupper-service-controller-57cdbb56c5-vc7s2   1/1     Running   0          34s
skupper-site-controller-d7b57964-gxms6        1/1     Running   0          51m
```

You can now navigate to the Skupper console.

```
$ kubectl get routes
```

Navigate to the `skupper` route and use `admin/admin` to log in.


For more information, visit the official [Skupper website](https://skupper.io)

# Uninstalling

## Uninstalling from Minikube

```
# Delete the skupper-site ConfigMap
kubectl delete -f examples/skupper-site-interior.yaml

# Deleting the Subscription
kubectl delete -f examples/k8s/20-sub.yaml

# Delete the CSV
kubectl delete csv skupper-operator.v0.0.1

# Deleting the OperatorGroup
kubectl delete -f examples/k8s/10-og.yaml

# Deleting the CatalogSource
kubectl delete -f examples/k8s/00-cs.yaml
```

## Uninstalling from OpenShift

```
# Delete the skupper-site ConfigMap
kubectl delete -f examples/skupper-site-interior.yaml

# Deleting the Subscription
kubectl delete -f examples/ocp/20-sub.yaml

# Delete the CSV
kubectl delete csv skupper-operator.v0.0.1

# Deleting the OperatorGroup
kubectl delete -f examples/ocp/10-og.yaml

# Deleting the CatalogSource
kubectl delete -f examples/ocp/00-cs.yaml
```

# Note for cluster-wide installations

If you want to try a cluster-wide installation, you don't need
to create the `OperatorGroup` as it is already defined at the
destination namespaces, so you just need to create the subscription
at the correct namespaces, see below.

## Cluster-wide installation on Minikube

On Minikube the `Subscription` needs to be defined at the `operators` namespace, like:

```
kubectl apply -f examples/k8s/20-sub-cluster-wide.yaml
```

## Cluster-wide installation on OpenShift

On OpenShift the `Subscription` needs to be defined at the `openshift-operators` namespace, like:

```
kubectl apply -f examples/ocp/20-sub-cluster-wide.yaml
```

# Building the bundle and index images

To build the bundle and index images, you just need to run: `make`.
