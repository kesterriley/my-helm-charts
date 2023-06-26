
# Master Replica MariaDB in Kubernetes

<!--- These are examples. See https://shields.io for others or to customize this set of shields. You might want to include dependencies, project status and licence info here --->
<!-- ![GitHub repo size](https://img.shields.io/github/repo-size/scottydocs/README-template.md)
![GitHub contributors](https://img.shields.io/github/contributors/scottydocs/README-template.md)
![GitHub stars](https://img.shields.io/github/stars/scottydocs/README-template.md?style=social)
![GitHub forks](https://img.shields.io/github/forks/scottydocs/README-template.md?style=social)
![Twitter Follow](https://img.shields.io/twitter/follow/scottydocs?style=social) -->

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![CircleCI](https://circleci.com/gh/kesterriley/my-helm-charts.svg?style=svg)](https://circleci.com/gh/kesterriley/my-helm-charts)
![GitHub stars](https://img.shields.io/github/stars/kesterriley/my-helm-charts?style=social)
![GitHub forks](https://img.shields.io/github/forks/kesterriley/my-helm-charts?style=social)

This project contains two helm charts that will install a **Galera Cluster** or a **Master and two Replica** MariaDB servers, sitting behind a pair of Maxscale proxy servers, providing fail over and master down detection and promotion.

**THIS PROJECT IS NOT FOR USE IN PRODUCTION**

CURRENTLY THE STORAGE IS SET TO RUN ON LOCAL DOCKER KUBERNETES DESKTOP


## Prerequisites

Before you begin, ensure you have met the following requirements:
<!--- These are just example requirements. Add, duplicate or remove as required --->
* You have a working Kubernetes Environment, in this example [Minikube](https://github.com/kesterriley/my-helm-charts/guides/minikube/README.md)
* * You must also have [Helm](https://github.com/kesterriley/my-helm-charts/guides/helm/README.md) installed.

## Installing *my-helm-repo*

To install *my-helm-repo*, follow these steps:

To install the repository:

```
helm repo add kesterriley-repo https://kesterriley.github.io/my-helm-charts/
```

To search repo:

```
helm search repo kdr
```

To refresh repo:

```
helm repo update
```

To remove repo:

```
helm repo remove kesterriley-repo
```

## Using *my-helm-repo*

To use *my-helm-repo*, follow these steps:

You must first create a NameSpace if there is not one:

```
kubectl create namespace uk
```

Building a Master / Replica cluster:

```
helm install mariadb kesterriley-repo/kdr-masterreplica --namespace=uk
```

Building a Galera Cluster:
```
helm install ukdc kesterriley-repo/kdr-galera --namespace=uk
```

Additional helm configuration options

| Description | Option |
|---|---|
| Set a Domain ID for the Cluster | --set galera.domainId=100 |
| Set the autoincrement offset | --set galera.autoIncrementOffset=1 |
| Where to clone from  | --set cloneRemote=usdc-kdr-galera-backupstream.us.svc.cluster.local  |
| A remote MaxScale to sync with  | --set remoteMaxscale=usdc-kdr-galera-masteronly.us.svc.cluster.local |
| Change master on failover name  | --set maxscale.changeMaster.name1=uktousauto |
| Change master on failover FQDN  | --set maxscale.changeMaster.host1=usdc-kdr-galera-masteronly.us.svc.cluster.local |

## Advanced uses

### Port Forwarding

It is possible to use port forwarding to connect directly to the installed and running helm chart.

To find the name of the service you want to forward to:

```
kubectl get svc -n uk
```

Once you have identified the port you can link to it via your local computer.

In Terminal A:

```
kubectl port-forward svc/masteronly -n uk 3306:3306
```

and in Terminal B:

```
mariadb -u<user> -p<password> -h127.0.0.1 -P3306 -e "select @@hostname, @@server_id;"
```

You can run the same thing but on a read write split service.

In Terminal A:

```
kubectl port-forward svc/rwsplit -n uk 3307:3307
```

and in Terminal B:

```
mariadb -u<user> -p<password> -h127.0.0.1 -P3307 -e "select @@hostname, @@server_id;"
```

### Port Connections

Instead of port forwarding you can connect directly to the IP address and port of a service.

To identify the IP address of the cluster run

```bash
➜  ~ kubectl cluster-info
Kubernetes master is running at https://192.168.64.2:8443
KubeDNS is running at https://192.168.64.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

and to identify the service port you run

```bash
➜  ~ kubectl get svc -n uk
NAME                                     TYPE        CLUSTER-IP      EXTERNAL-IP PORT(S)             AGE
masteronly                               NodePort    10.96.255.84    <none>        3306:30131/TCP      154m
rwsplit                                  NodePort    10.96.225.242   <none>        3307:30945/TCP      154m
```

In this example the port of the rwsplit service is `30945`.

Create two environment variables to make accessing this easier.

```bash
clusterip=192.168.64.2
portnumber=30945
```

## Demonstration

To demonstrate accessing and writting to the cluster.

### Master / Replica

You need four terminals.

On all four terminals create and set the `clusterip=192.168.64.2` and `portnumber=30945` environment variables.

On any terminal:

```bash
mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'CREATE DATABASE demo; CREATE TABLE demo.test (id SERIAL PRIMARY KEY, host VARCHAR(50) NOT NULL, created DATETIME) ENGINE=INNODB DEFAULT CHARSET=utf8;'
```

On any terminal:

```bash
mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'SHOW DATABASES'
```

Terminal One:

Watch the Pods:

```bash
watch "kubectl get pods -n uk"
```

Terminal Two:

Run a count on the database to watch the inserts:

```bash
watch "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'select count(*) from demo.test'"
```

Terminal Three:

Connect to MaxScale and run a watch:

```bash
kubectl exec -it -n uk mariadb-kdr-masterreplica-maxscale-active-6cb8df65fc-rwzb6 -- watch "maxctrl list servers"
```

Terminal Four:

Run an insert as a background task to run for about 5 minutes:

```bash
for ((i=1;i<=300;i++)); do mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'insert into demo.test SET host='@@hostname', created=now()'; [[  $? -eq 0 ]] && sleep 1 || { echo "Down at `date`"; sleep 1; } ; done &
```

You will notice the GTID on the Maxscale servers increase, as well as the count of the records in the database. Identify which server is running as the master on the MaxScale screen and kill it:

Terminal Four:

Kill the master node.

```bash
kubectl delete pod -n uk ukdc-kdr-galera-1
```

You will notice the MaxScale watch identifies the pod as down and moves the master, the insert script will fail for a few seconds (this time depends on the configuration) and then resumes inserting data. The count on Terminal Two carries on increasing. When the node comes back in service you will notice that it rejoins the cluster as a slave and syncs to the master.

You can now check the data in the database, and will note that there are different values for the insert.

```bash
mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber demo -e 'SELECT DISTINCT (host) FROM test'
```

```mysql
+-----------------------------+
| host                        |
+-----------------------------+
| mariadb-kdr-masterreplica-0 |
| mariadb-kdr-masterreplica-1 |
+-----------------------------+
```

## Contributing to *my-helm-repo*
<!--- If your README is long or you have some specific process or steps you want contributors to follow, consider creating a separate CONTRIBUTING.md file--->
To contribute to *my-helm-repo*, follow these steps:

1. Fork this repository.
2. Create a branch: `git checkout -b <branch_name>`.
3. Make your changes and commit them: `git commit -m '<commit_message>'`
4. Push to the original branch: `git push origin my-helm-repo/<location>`
5. Create the pull request.

Alternatively see the GitHub documentation on [creating a pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request).

## Contributors

Thanks to the following people who have contributed to this project:

* [@kesterriley](https://github.com/kesterriley)
* [@swade1987](https://github.com/swade1987)


## Contact

If you want to contact me you can reach me at kesterriley@hotmail.com.

## License
<!--- If you're not sure which open license to use see https://choosealicense.com/--->

This project uses the following license: [MIT](https://github.com/kesterriley/my-helm-charts/blob/master/LICENSE).
