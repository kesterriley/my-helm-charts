
# CREATE HELM REPO


To demonstrate:

Maxscale Active / Passive via the service

Collect the IP Address used for the nodePort

On Minikube run 'kubectl cluster-info'
then get the port 'kubectl get svc' and you want the second part of the port 3306:30923/TCP eg 30923

then in another terminal :

watch -n 0.5 "mysql -umariadb -pmariadb -h192.168.64.2 -P 30923 -e 'STATUS;' | grep \"Server version\""

and in another terminal

watch kubectl get pods

and in another terminal kill a pod

kubectl delete pods kdr-galera-maxscale-active-864588545d-qk25r

login in to maxscale server and do watch maxctrl list services


# MaxScale Gui

``` 
kubectl port-forward svc/ukdc-kdr-galera-gui -n uk 8989:8989
```

To test with sysbench

On Terminal A:

```
kubectl port-forward svc/ukdc-kdr-galera-rwsplit -n uk 3307:3307
```

or for Async replication:

```
kubectl port-forward svc/rwsplit -n uk 3307:3307
```

On Terminal B:

```

mariadb -uMARIADB_USER -pmariadb -hlocalhost -P3307 -e "CREATE DATABASE sbtest"

sysbench oltp_common \
  --mysql-user=MARIADB_USER \
  --mysql-password=mariadb \
	--mysql-db=sbtest \
	--mysql-port=3307 \
	--mysql-host=127.0.0.1 \
	--db-driver=mysql \
	--table-size=100000 \
	--tables=16 \
	prepare

sysbench oltp_read_write \
  --time=60 \
  --mysql-user=MARIADB_USER \
	--mysql-password=mariadb \
	--mysql-db=sbtest \
	--mysql-port=3307 \
	--mysql-host=127.0.0.1 \
	--db-driver=mysql \
	--threads=10 \
	--report-interval=1 \
	--table-size=100000 \
	--tables=16 \
	--skip-trx=true
	run
	
	
	sysbench oltp_common --mysql-user=MARIADB_USER \
	--mysql-password=mariadb \
	--mysql-db=sbtest \
	--mysql-port=3307 \
	--mysql-host=127.0.0.1 \
	--db-driver=mysql \
	--tables=16 \
	 cleanup

```

# Cron failedJobsHistoryLimit
kubectl get cronjob -n uk
kubectl get jobs -n uk --watch

kubectl get pods -A

will show you cron job, then you claimName

 kubectl logs -n uk -f ukdc-kdr-galera-cronjob-1596363060-tsxf9


# To restore from a backup:

1. Identify backup name
2. Scale Statefulset to 0
3. kubectl scale statefulsets ukdc-kdr-galera -n uk --replicas=1


###TO SET UP REPLICATION BETWEEN DATA CENTRES

cd /Users/kester/src/github.com/kesterriley/helm-charts/charts

kubectl create namespace us
kubectl create namespace uk
kubectl create namespace eu

# Auto increment offset can not be 0

helm install ukdc kdr-galera --set galera.domainId=100 --set galera.autoIncrementOffset=1 --namespace=uk
helm install usdc kdr-galera --set galera.domainId=200 --set galera.autoIncrementOffset=4 --namespace=us
helm install eudc kdr-galera --set galera.domainId=300 --set galera.autoIncrementOffset=7 --namespace=eu


ON THE UK SERVER:

kubectl exec -it ukdc-kdr-galera-0 -n uk -- /bin/bash
mariadb -umariadb -pmariadb -h127.0.0.1

CHANGE MASTER 'uk-to-us' TO MASTER_HOST="usdc-kdr-galera-masteronly.us.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_LOG_FILE="mariadb-node.000005",MASTER_LOG_POS=345; START SLAVE 'uk-to-us';

STOP SLAVE 'uk-to-us';CHANGE MASTER 'uk-to-us' TO MASTER_HOST="usdc-kdr-galera-masteronly.us.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_USE_GTID=slave_pos;START SLAVE 'uk-to-us';

CHANGE MASTER 'uk-to-eu' TO MASTER_HOST="eudc-kdr-galera-masteronly.eu.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_USE_GTID=slave_pos;START SLAVE 'uk-to-eu';

CREATE DATABASE UK;

ON THE US SERVER:

kubectl exec -it usdc-kdr-galera-0 -n us -- /bin/bash
mariadb -umariadb -pmariadb -h127.0.0.1

CHANGE MASTER 'us-to-uk' TO MASTER_HOST="ukdc-kdr-galera-masteronly.uk.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_LOG_FILE="mariadb-node.000005",MASTER_LOG_POS=345; START SLAVE 'us-to-uk';

STOP SLAVE 'us-to-uk';CHANGE MASTER 'us-to-uk' TO MASTER_HOST="ukdc-kdr-galera-masteronly.uk.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_USE_GTID=slave_pos;START SLAVE 'us-to-uk';

CHANGE MASTER 'us-to-eu' TO MASTER_HOST="eudc-kdr-galera-masteronly.eu.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_USE_GTID=slave_pos;START SLAVE 'us-to-eu';

CREATE DATABASE US;

ON THE EU SERVER:

kubectl exec -it eudc-kdr-galera-0 -n eu -- /bin/bash
mariadb -umariadb -pmariadb -h127.0.0.1

CHANGE MASTER 'eu-to-uk' TO MASTER_HOST="ukdc-kdr-galera-masteronly.uk.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_LOG_FILE="mariadb-node.000005",MASTER_LOG_POS=345; START SLAVE 'eu-to-uk' ;

STOP SLAVE 'eu-to-uk'; CHANGE MASTER 'eu-to-uk' TO MASTER_HOST="ukdc-kdr-galera-masteronly.uk.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_USE_GTID=slave_pos;START SLAVE 'eu-to-uk' ;

CHANGE MASTER 'eu-to-us' TO MASTER_HOST="usdc-kdr-galera-masteronly.us.svc.cluster.local",MASTER_PORT=3306, MASTER_USER="mariadb",MASTER_PASSWORD="mariadb",MASTER_USE_GTID=slave_pos;START SLAVE 'eu-to-us';

CREATE DATABASE EU;



ON one server:

mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$euport -e 'CREATE DATABASE demo;'
mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$euport -e 'CREATE TABLE demo.test (id SERIAL PRIMARY KEY, host VARCHAR(50) NOT NULL, created DATETIME) ENGINE=INNODB DEFAULT CHARSET=utf8 ;'

To check maxscale:

kubectl exec -it -n uk XXXXXX -- maxctrl list servers
kubectl exec -it -n us XXXXXX -- maxctrl list servers
kubectl exec -it -n eu XXXXXX -- maxctrl list servers

To check slave replication:

kubectl exec -it -n us usdc-kdr-galera-1 -- mariadb -uMARIADB_USER -pmariadb -h127.0.0.1 -e"SHOW ALL SLAVES STATUS\G"

kubectl exec -it -n uk ukdc-kdr-galera-1 -- mariadb -uMARIADB_USER -pmariadb -h127.0.0.1 -e"SHOW ALL SLAVES STATUS\G"

kubectl exec -it -n eu eudc-kdr-galera-1 -- mariadb -uMARIADB_USER -pmariadb -h127.0.0.1 -e"SHOW ALL SLAVES STATUS\G"


get ip: kubectl cluster-info
get rw service:  kubectl get service --all-namespaces | grep rw

clusterip=192.168.64.2; euport=30869; ukport=30698; usport=31217;

THEN OPEN SIX TERMINALS:


in three of them changing port and IP

EU:
watch -n2 "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$euport -e 'select host,count(*) from demo.test group by host'"

UK:
watch -n2 "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$ukport -e 'select host,count(*) from demo.test group by host'"

US:
watch -n2 "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$usport -e 'select host,count(*) from demo.test group by host'"


in the other three:

EU:
for ((i=1;i<=10000;i++));
do
    mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$euport -e "insert into demo.test SET host='EU', created=now()"
done

UK:
for ((i=1;i<=10000;i++));
do
    mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$ukport -e "insert into demo.test SET host='UK', created=now()"
done


US:
for ((i=1;i<=10000;i++));
do
    mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$usport -e "insert into demo.test SET host='US', created=now()"
done



delete a maxcsale from eu

kubectl delete pod -n eu eudc-kdr-galera-maxscale-active-75b9c4849d-fbqxf


delete a galera node from uk

kubectl delete pod -n uk ukdc-kdr-galera-2



helm delete eudc --namespace=eu; helm delete ukdc --namespace=uk; helm delete usdc --namespace=us;






### COOL STUFF

you could set the CLONEFROMREMOTE variable (pass it on the cli), to build one cluster from another. This will also need the remote maxscale server setting:

helm install ukdc kdr-galera --set galera.domainId=100 --set galera.autoIncrementOffset=1 --namespace=uk


helm install usdc kdr-galera --set galera.domainId=200 --set cloneRemote=ukdc-kdr-galera-backupstream.uk.svc.cluster.local  --set remoteMaxscale=ukdc-kdr-galera-masteronly.uk.svc.cluster.local --set galera.autoIncrementOffset=4 --namespace=us


helm install eudc kdr-galera --set galera.domainId=300 --set galera.autoIncrementOffset=7 --set cloneRemote=usdc-kdr-galera-backupstream.us.svc.cluster.local  --set remoteMaxscale=usdc-kdr-galera-masteronly.us.svc.cluster.local --namespace=eu



Once the clusters are up, configure them to work in multiple source replication

kubectl exec -it -n us usdc-kdr-galera-0 -- /usr/local/bin/replication_configuration.sh eudc-kdr-galera-masteronly.eu.svc.cluster.local mariadb mariadb 127.0.0.1 mariadb mariadb


kubectl exec -it -n eu eudc-kdr-galera-0 -- /usr/local/bin/replication_configuration.sh ukdc-kdr-galera-masteronly.uk.svc.cluster.local mariadb mariadb 127.0.0.1 mariadb mariadb



kubectl exec -it -n uk ukdc-kdr-galera-0 -- /usr/local/bin/replication_configuration.sh eudc-kdr-galera-masteronly.eu.svc.cluster.local mariadb mariadb 127.0.0.1 mariadb mariadb

kubectl exec -it -n uk ukdc-kdr-galera-0 -- /usr/local/bin/replication_configuration.sh usdc-kdr-galera-masteronly.us.svc.cluster.local mariadb mariadb 127.0.0.1 mariadb mariadb




to invoke the script for changing master automatically


helm install usdc kdr-galera --set galera.domainId=200 --set cloneRemote=ukdc-kdr-galera-backupstream.uk.svc.cluster.local  --set remoteMaxscale=ukdc-kdr-galera-masteronly.uk.svc.cluster.local --set galera.autoIncrementOffset=4 --namespace=us --set maxscale.changeMaster.name1=ustoukauto  --set maxscale.changeMaster.host1=ukdc-kdr-galera-masteronly.uk.svc.cluster.local


maxscale:
  enabled: true
  passive: true
  notify:
    email: kester.riley@mariadb.com
  changeMaster:
    name1: none
    name2: none
    host1: none
