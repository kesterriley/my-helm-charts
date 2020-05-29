
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

## Prerequisites

Before you begin, ensure you have met the following requirements:
<!--- These are just example requirements. Add, duplicate or remove as required --->
* You have a working Kubernetes Environment, in this example Minikube `<guide/link/documentation_related_to_project>`
* You have helm installed `<guide/link/documentation_related_to_project>`

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

Building a Master / Replica cluster:

```
helm install mariadb kesterriley-repo/kdr-masterreplica
```

Building a Galera Cluster:
```
helm install ukdc kesterriley-repo/kdr-galera
```

Additional helm configuration options

| Description | Option |
|---|---|
| Set a Domain ID for the Cluster | --set galera.domainId=100 |
| Set the autoincrement offset | --set galera.autoIncrementOffset=1 |
| Set the namespace  | --namespace=uk |
| Where to clone from  | --set cloneRemote=usdc-kdr-galera-backupstream.us.svc.cluster.local  |
| A remote MaxScale to sync with  | --set remoteMaxscale=usdc-kdr-galera-masteronly.us.svc.cluster.local |
| Change master on failover name  | --set maxscale.changeMaster.name1=uktousauto |
| Change master on failover FQDN  | --set maxscale.changeMaster.host1=usdc-kdr-galera-masteronly.us.svc.cluster.local |

## Contributing to *my-helm-repo*
<!--- If your README is long or you have some specific process or steps you want contributors to follow, consider creating a separate CONTRIBUTING.md file--->
To contribute to *my-helm-repo*, follow these steps:

1. Fork this repository.
2. Create a branch: `git checkout -b <branch_name>`.
3. Make your changes and commit them: `git commit -m '<commit_message>'`
4. Push to the original branch: `git push origin *my-helm-repo*/<location>`
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
