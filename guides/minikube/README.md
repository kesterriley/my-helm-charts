# MiniKube on Mac

MiniKube runs inside a Virtual Machine on your Mac, sometime this Virtual Machine may run out of resouces and you will need to connect to the instance. See more below under SSH MiniKube.

## Prerequisites

Before you begin, ensure you have VirtualBox installed:
<!--- These are just example requirements. Add, duplicate or remove as required --->
* To install Virtual Box please visit  https://www.virtualbox.org/wiki/Downloads


## Installing MiniKube

To install MiniKube, follow these steps:

```
mkdir ~/minikube
cd ~/minikube
curl -Lo minikube https://github.com/kubernetes/minikube/releases/download/v1.6.2/minikube-darwin-amd64
  chmod +x ~/minikube/minikube
  sudo mv ~/minikube/minikube /usr/local/bin/
```

## Starting MiniKube

You need to ensure MiniKube has enough resources for the workload you are using, on my Mac this is the configuration I use

```
minikube start -p myprofile --memory=8192 --cpus=4 --disk-size=50g
````

## Stoping MiniKube

To Stop the MiniKube process

```
minikube stop
````

## SSH MiniKube

To SSH in to the MiniKube server

```
minikube ssh -p myprofile
````

### Clear up Disk Space

Sometime it is required to clean up the MiniKube server disk space. SSH in to Minikube.

To check the disk space you can `docker system df`. You can reclaim the disk space by running `docker system prune -a`.


## Cluster info

To check the cluster is up and running you can run

```
kubectl cluster-info
```
