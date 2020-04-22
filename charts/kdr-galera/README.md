
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

login in to maxscle server and do watch maxctrl list services



TO SET UP REPLICATION BETWEEN DATA CENTRES

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

CREATE DATABASE demo;
CREATE TABLE demo.test (id SERIAL PRIMARY KEY, host VARCHAR(50) NOT NULL, created DATETIME) ENGINE=INNODB DEFAULT CHARSET=utf8 ;





get ip: kubectl cluster-info
get rw service:  kubectl get service --all-namespaces | grep rw

clusterip=192.168.64.2; euport=30869; ukport=30698; usport=31217;

THEN OPEN SIX TERMINALS:


in three of them changing port and IP

EU:
watch -n0.5 "mysql -umariadb -pmariadb -h$clusterip -P$euport -e 'select count(*) from demo.test'"

UK:
watch -n0.5 "mysql -umariadb -pmariadb -h$clusterip -P$ukport -e 'select count(*) from demo.test'"

US:
watch -n0.5 "mysql -umariadb -pmariadb -h$clusterip -P$usport -e 'select count(*) from demo.test'"


in the other three:

EU:
for ((i=1;i<=10000;i++));
do
   mysql -umariadb -pmariadb -h$clusterip -P$euport -e "insert into demo.test SET host='EU', created=now()"
done

UK:
for ((i=1;i<=10000;i++));
do
   mysql -umariadb -pmariadb -h$clusterip -P$ukport -e "insert into demo.test SET host='UK', created=now()"
done


US:
for ((i=1;i<=10000;i++));
do
   mysql -umariadb -pmariadb -h$clusterip -P$usport -e "insert into demo.test SET host='US', created=now()"
done



delete a maxcsale from eu

kubectl delete pod -n eu eudc-kdr-galera-maxscale-active-75b9c4849d-fbqxf


delete a galera node from uk

kubectl delete pod -n uk ukdc-kdr-galera-2



helm delete eudc --namespace=eu; helm delete ukdc --namespace=uk; helm delete usdc --namespace=us;
