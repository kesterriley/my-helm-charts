# Helm on Mac

Helm is a package manager, used by Kubernetes. To be able to install helm charts you must have helm installed.


## Prerequisites

Before you begin, ensure you have VirtualBox installed:
<!--- These are just example requirements. Add, duplicate or remove as required --->
* To install Virtual Box please visit https://www.virtualbox.org/wiki/Downloads
* You must also have [Minikube](https://github.com/kesterriley/my-helm-charts/guides/minikube/README.md) installed.


## Installing Helm

To install Helm, use brew:

```
brew install kubernetes-helm
```

Once installed you need to initialise helm:

```
helm init
```

and add in the kubernetes helm repo and updarte helm:

```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
```
