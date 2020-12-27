
RECORD DEMO


# Start minikube


`make minikubeStart`

Lets start up a Dashboard in another terminal :

minikube dashboard --url -p myprofile



# Deploy UK Primary / Replica cluster


`make buildMasterReplicaDemoUK`

`watch kubectl get pods -n uk
`

# Setup access to MaxScale

get the active maxscale node:

 `kubectl get pods -n uk`

 set MAXACTIVE=

List Active servers

`kubectl exec -it -n uk $MAXACTIVE -- maxctrl list servers`


# Setup access to Database

`clusterip=192.168.64.2`

get Port number for service:

`kubectl get svc -n uk rwsplit`

then set the port number: (CTRL SHIFT I)

`portnumber=31748`

`mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e  "select @@hostname, @@server_id;"`

create a Database : (CTRL SHIFT I OFF)

`mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'CREATE DATABASE demo; CREATE TABLE demo.test (id SERIAL PRIMARY KEY, host VARCHAR(50) NOT NULL, created DATETIME) ENGINE=INNODB DEFAULT CHARSET=utf8;'`

Check all three servers:

```
kubectl exec -it -n uk mariadb-kdr-masterreplica-0 -- mariadb -uMARIADB_USER -pmariadb -h127.0.0.1 -e 'show databases;'
kubectl exec -it -n uk mariadb-kdr-masterreplica-1 -- mariadb -uMARIADB_USER -pmariadb -h127.0.0.1 -e 'show databases;'
kubectl exec -it -n uk mariadb-kdr-masterreplica-2 -- mariadb -uMARIADB_USER -pmariadb -h127.0.0.1 -e 'show databases;'
```

Now start inserting data:

```
watch -n2 "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'START TRANSACTION; insert into demo.test SET host='@@hostname', created=now(); select @@hostname; commit;'"
```

you can run this:

`watch "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e  'select count(*), @@hostname, @@server_id from demo.test;'"`


then delete one of the pods and watch the select:

watch the logs
`kubectl logs -f -n uk $MAXACTIVE`

delete the pod:

`kubectl -n uk delete pod mariadb-kdr-masterreplica-1`

check MaxScale:

`kubectl exec -it -n uk $MAXACTIVE -- maxctrl list servers`


Now delete the master and watch the reads and writes:


`kubectl -n uk delete pod mariadb-kdr-masterreplica-0`

`kubectl exec -it -n uk $MAXACTIVE -- maxctrl list servers`

Now look where the reads and writes are coming from....


The next thing to do is make the tests only connect to the Master Only.

`kubectl get svc -n uk masteronly`

on all terminals: (CTRL SHIFT I)

`portnumber=31076`


Now start inserting data:

`watch -n2 "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'START TRANSACTION; insert into demo.test SET host='@@hostname', created=now(); select @@hostname; commit;'"`

you can run this:

`watch "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e  'select count(*), @@hostname, @@server_id from demo.test;'"`

All the reads and writes are to the same seerver. Delete the pod that is currently the master:

`kubectl -n uk delete pod mariadb-kdr-masterreplica-0`

and after a few seconds a new master takes over.


Switch back to Read Write split

get Port number for service:

`kubectl get svc -n uk rwsplit`

then set the port number: (CTRL SHIFT I)

`portnumber=31748`

Now we could use sysbench:

`mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e "CREATE DATABASE sysbench"
`
then create the tables:

`sysbench oltp_common --mysql-user=MARIADB_USER --mysql-password=mariadb --mysql-port=$portnumber --mysql-db=sysbench --db-driver=mysql --mysql-host=$clusterip --table-size=100000 prepare`


run the test:

We are going to run SysBench with 32 threads and a rate of 1000 transactions per second.


`sysbench oltp_read_write --time=60 --db-driver=mysql --mysql-user=MARIADB_USER --mysql-password=mariadb --mysql-port=$portnumber --mysql-host=$clusterip --mysql-db=sysbench --threads=32 --report-interval=1 --rate=1000 run`


clean up

`sysbench oltp_common --mysql-user=MARIADB_USER --mysql-password=mariadb --mysql-port=$portnumber --mysql-db=sysbench --db-driver=mysql --mysql-host=$clusterip cleanup`


((RECORD RESULTS))


# Clean Up

`helm delete -n uk mariadb`

and delete the pvc as these persistent volumes will remain otherwise.

kubectl delete pvc -n uk datadir-mariadb-kdr-masterreplica-0 datadir-mariadb-kdr-masterreplica-1 datadir-mariadb-kdr-masterreplica-2


########## NOW BUILD A GALERA CLUSTER ####################

```
helm install ukdc kesterriley-repo/kdr-galera --namespace=uk
```

kubectl get svc -n uk ukdc-kdr-galera-rwsplit

(CTRL SHIFT I)

clusterip=192.168.64.2
portnumber=30945

Set the MAXACTIVE;

kubectl get pods -n uk
MAXAVTIVE=<maxscale>


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



## Add monitoring to DB Beaver of the master server.

MonYOG do not have a MAC version and I do not have a licence for it


kubectl get svc -n uk
kubectl -n uk port-forward pod/ukdc-kdr-galera-0 3306:3306

Insert a load of data:

`watch -n0.5 "mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e 'START TRANSACTION; insert into demo.test SET host='@@hostname', created=now(); select @@hostname; commit;'"`

When port forwarding you can also use mytop:

`mytop -uMARIADB_USER -pmariadb -h127.0.0.1 -P3306`

Now we could use sysbench:

`
mariadb -uMARIADB_USER -pmariadb -h$clusterip -P$portnumber -e "CREATE DATABASE sysbench"
`
then create the tables:

`sysbench oltp_common --mysql-user=MARIADB_USER --mysql-password=mariadb --mysql-port=$portnumber --mysql-db=sysbench --db-driver=mysql --mysql-host=$clusterip --table-size=100000 prepare`


run the test:

`sysbench oltp_read_write --time=60 --db-driver=mysql --mysql-user=MARIADB_USER --mysql-password=mariadb --mysql-port=$portnumber --mysql-host=$clusterip --mysql-db=sysbench --threads=32 --report-interval=1 --rate=1000 run`

do a list servers when running

```
kubectl exec -it -n uk $MAXACTIVE -- maxctrl list servers
```

you may notice it has more connections thasn the Primary / Replica installation as this has threads running for Galera.


Repeat test with different amount of threads to show that the system has better response times with lower  connections -- if there is a queue the system is overloaded.

Try 500 - system has a high latency but we can see the system is managing about 300 transactions per second, so we will try this. Now lets try 200 -- we can see the average latency is lower...

PLEASE REMEMBER THESE ARE SIGNIFICANTLY LOWER THAN A PRODUCTION SYSTEM DUE TO THE FACT WE ARE RUNNING THIS ALL ON MY MAC.


clean up

`sysbench oltp_common --mysql-user=MARIADB_USER --mysql-password=mariadb --mysql-port=$portnumber --mysql-db=sysbench --db-driver=mysql --mysql-host=$clusterip cleanup`


now connect another cluster !!

# Clean Up
helm delete -n uk ukdc


`make minikubeStop`


STOP DEMO RECORD
