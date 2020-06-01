init:
	clear
	@echo "Run make with the following commands:"
	@echo ""
	@echo "... buildMonitoringCluster"
	@echo ""
	@echo "... buildMasterReplicaDemoUK"
	@echo ""
	@echo "... buildBasicGaleraClusterUK"
	@echo "... buildBasicGaleraClusterUS"
	@echo "... buildBasicGaleraClusterEU"
	@echo ""
	@echo "... buildGaleraClusterUSCloneFromUK"
	@echo "... buildGaleraClusterUKCloneFromUS"
	@echo "... buildGaleraClusterEUCloneFromUS"
	@echo ""
	@echo "... buildGaleraClusterUSCloneFromUKWithMaxscaleReplication"
	@echo "... buildGaleraClusterUKCloneFromUSWithMaxscaleReplication"
	@echo ""
	@echo ""
	@echo "Before any of this works you must install the helm repo:"
	@echo "... helm repo add kesterriley-repo https://kesterriley.github.io/my-helm-charts/"
	@echo "... or to update: helm repo update"

buildMonitoringCluster:
	@echo "Creating a Prometheous and Grafana installation"
	helm install prometheus -n monitoring stable/prometheus
	helm install grafana -n grafana stable/grafana

buildMasterReplicaDemoUK:
	@echo "Building a Master / Replica cluster"
	helm install mariadb kesterriley-repo/kdr-masterreplica -n uk

buildBasicGaleraClusterUK:
	@echo "Building a Galera Cluster in the UK DC"
	@echo "... with a galera DomainId of 100"
	@echo "... and an autoIncrementOffset of 1"
	helm install ukdc kesterriley-repo/kdr-galera -n uk \
	  --set galera.domainId=100 \
		--set galera.autoIncrementOffset=1

buildBasicGaleraClusterUS:
	@echo "Building a Galera Cluster in the US DC"
	@echo "... with a galera DomainId of 200"
	@echo "... and an autoIncrementOffset of 4"
	helm install usdc kesterriley-repo/kdr-galera -n us \
	  --set galera.domainId=200 \
		--set galera.autoIncrementOffset=4

buildBasicGaleraClusterEU:
	@echo "Building a Galera Cluster in the EU DC"
	@echo "... with a galera DomainId of 300"
	@echo "... and an autoIncrementOffset of 7"
	helm install usdc kesterriley-repo/kdr-galera -n eu \
	  --set galera.domainId=300 \
		--set galera.autoIncrementOffset=7

buildGaleraClusterUSCloneFromUK:
	@echo "Building a Galera Cluster in the US DC"
	@echo "... with a galera DomainId of 200"
	@echo "... and an autoIncrementOffset of 4"
	@echo "... and cloning from the UK DC"
	@echo "... and establishing Replicaton"
	helm install usdc kesterriley-repo/kdr-galera \
	  --set galera.domainId=200 \
		--set galera.autoIncrementOffset=4 \
		--namespace=us \
		--set cloneRemote=ukdc-kdr-galera-backupstream.uk.svc.cluster.local  \
		--set remoteMaxscale=ukdc-kdr-galera-masteronly.uk.svc.cluster.local

buildGaleraClusterUKCloneFromUS:
	@echo "Building a Galera Cluster in the UK DC"
	@echo "... with a galera DomainId of 100"
	@echo "... and an autoIncrementOffset of 1"
	@echo "... and cloning from the US DC"
	@echo "... and establishing Replicaton"
	helm install ukdc kesterriley-repo/kdr-galera \
	  --set galera.domainId=100 \
		--set galera.autoIncrementOffset=1 \
		--namespace=uk \
		--set cloneRemote=usdc-kdr-galera-backupstream.us.svc.cluster.local  \
		--set remoteMaxscale=usdc-kdr-galera-masteronly.us.svc.cluster.local

buildGaleraClusterEUCloneFromUS:
	@echo "Building a Galera Cluster in the US DC"
	@echo "... with a galera DomainId of 300"
	@echo "... and an autoIncrementOffset of 7"
	@echo "... and cloning from the US DC"
	@echo "... and establishing Replicaton"
	helm install usdc kesterriley-repo/kdr-galera \
	  --set galera.domainId=300 \
		--set galera.autoIncrementOffset=7 \
		--namespace=eu \
		--set cloneRemote=usdc-kdr-galera-backupstream.us.svc.cluster.local  \
		--set remoteMaxscale=usdc-kdr-galera-masteronly.us.svc.cluster.local

buildGaleraClusterUSCloneFromUKWithMaxscaleReplication:
	@echo "Building a Galera Cluster in the US DC"
	@echo "... with a galera DomainId of 200"
	@echo "... and an autoIncrementOffset of 4"
	@echo "... and cloning from the UK DC"
	@echo "... and configuring replication from the UK"
	helm install usdc kesterriley-repo/kdr-galera \
	  --set galera.domainId=200 \
		--set galera.autoIncrementOffset=4 \
		--namespace=us \
		--set cloneRemote=ukdc-kdr-galera-backupstream.uk.svc.cluster.local  \
		--set remoteMaxscale=ukdc-kdr-galera-masteronly.uk.svc.cluster.local \
		--set maxscale.changeMaster.name1=ustoukauto  \
		--set maxscale.changeMaster.host1=ukdc-kdr-galera-masteronly.uk.svc.cluster.local

buildGaleraClusterUKCloneFromUSWithMaxscaleReplication:
	@echo "Building a Galera Cluster in the UK DC"
	@echo "... with a galera DomainId of 100"
	@echo "... and an autoIncrementOffset of 1"
	@echo "... and cloning from the US DC"
	@echo "... and configuring replication from the US"
	helm install ukdc kesterriley-repo/kdr-galera \
	  --set galera.domainId=100 \
		--set galera.autoIncrementOffset=1 \
		--namespace=uk \
		--set cloneRemote=usdc-kdr-galera-backupstream.us.svc.cluster.local  \
		--set remoteMaxscale=usdc-kdr-galera-masteronly.us.svc.cluster.local \
		--set maxscale.changeMaster.name1=uktousauto  \
		--set maxscale.changeMaster.host1=usdc-kdr-galera-masteronly.us.svc.cluster.local
