# Release procedure

[repository]: https://github.com/skupperproject/skupper-operator
[skupper repository]: https://github.com/skupperproject/skupper
[operatorhubio]: https://operatorhub.io
[operatorhub]: https://github.com/k8s-operatorhub/community-operators
[community-operators]: https://github.com/redhat-openshift-ecosystem/community-operators-prod.git

## Requirements

* operator-sdk >= 1.33
* opm version >= 1.35 (will be downloaded if absent)
* podman version >= 4.0
* python version > 3.9

## Branching

Releases are handled in separate branches, created directly on the [skupper-operator repository][repository].

Branches should be named: `<MAJOR>.<MINOR>` version, in example: `1.6`.

* If the respective branch already exists on the [repository], check it out, cherry-pick eventual
changes merged to the `main` branch and continue working from there.
* In case the branch does not yet exist, make sure to create it on top of the main branch.

## Preparing updates

Now that the branching is done, we need to specify the Skupper component versions that will be used
by the respective release.

### Get the new versions

You need to have the following information handy:

* **New operator version**

  The new operator version to be released, and the one that will be part of the CSV.
  This version will also be the version displayed on the Operator Hub and to define the
  operator channel names where the new version will be available.

  Example: **1.6.0**


* **Current version**

  The version to be used as a base for the new manifests to be built on top of.
  It is usually the latest released version.

  Example: **1.5.3**


* **Replaces version**

  The installed CSV version to be replaced by this new version.
  It is usually the same as the current version, but eventually when we have
  release candidate versions, the version to be replaced should not be the release
  candidate version, but a released version.

  Example: **1.5.3**


* **Skupper Router Tag**

  The skupper-router tag (from quay.io) to be used by the update scripts to consume
  the digest SHA and use it in the bundle manifests.

  In case you are not sure on the tag to use, you can identify it by looking at the 
  [skupper repository] under `pkg/images/images.go`

  Example: **2.5.2**


* **Skupper Controller Tag**

  The skupper controller images tag (from quay.io) to be used by the update scripts to consume
  the digest SHAs and use them in the bundle manifests.

  In case you are not sure on the tag to use, you can identify it by looking at the
  [skupper repository] under `pkg/images/images.go`

  Example: **1.6.0**


* **Prometheus Tag**

  The prometheus image tag (from quay.io) to be used by the update scripts to consume
  the digest SHA and use them in the bundle manifests.

  In case you are not sure on the tag to use, you can identify it by looking at the
  [skupper repository] under `pkg/images/images.go`

  Example: **v2.42.0**


* Oauth Proxy Tag (i.e.: 4.14.0)

  The OAUTH Proxy image tag (from quay.io) to be used by the update scripts to consume
  the digest SHA and use them in the bundle manifests.

  In case you are not sure on the tag to use, you can identify it by looking at the
  [skupper repository] under `pkg/images/images.go`

  Example: **4.14.0**


### Create the new bundle

1. Once you have all the new versions handy, next thing do so is to update the `env.sh` script
with all the information to be used.
2. Then you must source the env.sh script: `source env.sh`
3. Run the update script: `./prepare-update.sh`

At this point, the bundle has been updated, but just locally.
You must then validate if all changes look good before proceeding.

## Building and pushing updated images

Once everything has been validated, it is time to build and push the bundle,
which will push two images onto quay.io (with the respective new version tag, i.e.: **1.6.0**).

Along with that, it will also update the catalog index file.

To do that, run: `make`.

## Testing

Make sure you test the updated instructions, defined through the [README.md](README.md)
against a minikube and an OpenShift (or CRC) cluster.

## Pushing changes to the release branch

### Commit and push

Now that the new bundle (index image and catalog) have been pushed,
it is time to commit your changes and raise a PR.

### Pushing a release tag

Once your PR has been reviewed and merged, you should push a version tag to the [repository].

Here is an example for version 1.6.0 (considering remote [repository] is called upstream):
```
git tag 1.6.0
git push upstream 1.6.0
```

Once this is done, the Skupper Operator is released.

Now it is time to make it public by creating pull requests to the [Operator Hub][operatorhub] and
to the [Openshift Community Operators][community-operators] repositories.

## OperatorHub

The Skupper Operator is also available at the upstream [Operator Hub portal][operatorhubio].

Every time a new version is released, we must also update the [Operator Hub repository][operatorhub].

Changes done to the [Operator Hub repository][operatorhub] will show up in the https://operatorhub.io after
the PR ir approved and merged (it takes some time, as new images are built after PR is merged).

If you haven't already done so, clone the [Operator Hub repository][operatorhub].

### Branch

The first thing to do, inside the [Operator Hub repository][operatorhub], is to create a new branch,
naming it using pattern similar to this one: `upd-skupper-<version>`.

In example: `upd-skupper-1.6.0`.

Make sure this branch is created on top of the main branch of the [Operator Hub repository][operatorhub].

### Update

Now, inside the [Operator Hub repository][operatorhub], make sure that the `env.sh` script is sourced in
your current shell session and then execute the following command:

**_NOTE:_** The command below will run from the main branch, if you need to run it from your specific
branch, make sure to update the command before executing.

```shell
curl -s https://raw.githubusercontent.com/skupperproject/skupper-operator/main/scripts/operatorhub.sh | sh
```

The script will make all necessary changes locally.
Next you must commit your changes (sign your commit) and raise a PR.

### PR

When you create the PR, make sure you populate the template accordingly.
You can remove the section for "new operators" from the template and add
a ticker `[x]` to all items, to state you have followed all the rules.

## Community Operators (openshift)

The Skupper Operator is also available on the Operator Hub of OpenShift and CRC clusters,
as part of the Community Operators catalog.

Every time a new version is released, we must also update the [Community Operators repository][community-operators].

Changes done to the [Community Operators repository][community-operators] will show up in the Community Operators
catalog after the PR ir approved and merged (it takes some time, as new images are built after PR is merged).

If you haven't already done so, clone the [Community Operators repository][community-operators].

The procedure is exactly the same done previously to OperatorHub.

### Branch

The first thing to do, inside the [Community Operators repository][community-operators], is to create a new branch,
naming it using pattern similar to this one: `upd-skupper-<version>`.

In example: `upd-skupper-1.6.0`.

Make sure this branch is created on top of the main branch of the [Community Operators repository][community-operators].

### Update

Now, inside the [Community Operators repository][community-operators], make sure that the `env.sh` script is sourced in
your current shell session and then execute the following command:

**_NOTE:_** The command below will run from the main branch, if you need to run it from your specific
branch, make sure to update the command before executing.

```shell
curl -s https://raw.githubusercontent.com/skupperproject/skupper-operator/main/scripts/operatorhub.sh | sh
```

The script will make all necessary changes locally.
Next you must commit your changes (sign your commit) and raise a PR.

### PR

When you create the PR, make sure you populate the template accordingly.
You can remove the section for "new operators" from the template and add
a ticker `[x]` to all items, to state you have followed all the rules.
