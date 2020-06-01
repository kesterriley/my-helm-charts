# Prometheus on MiniKube

To run prometheous on Minikube, you need to ensure you have minikube and helm running.


## Installation

### Namespace Creation

First of all, you need to ensure there is a namespace `monitoring` and `grafana` available.

```
kubectl get namespaces
```

If it is not available you can create it:

```
kubectl create namespace monitoring
kubectl create namespace grafana
```

### Intall Prometheus

```
helm install prometheus -n monitoring stable/prometheus
```

### Intall Grafana

```
helm install grafana -n grafana -f monitoring/grafana/values.yaml stable/grafana
```

## Configure

To run the Grafana Dashboard, you need to first extract the admin password.

```
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

You can then export the POD NAME and use Port Forwarding:

```
export POD_NAME=$(kubectl get pods --namespace grafana  -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace grafana port-forward $POD_NAME 3000
```

Login to Prometheous and add a dats source the url is `http://prometheus-server.monitoring.svc.cluster.local`
