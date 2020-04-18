# my-helm-charts
Helm Chart Repository for my playground

Using Git Hub pages based upon this blog:

https://tech.paulcz.net/blog/creating-a-helm-chart-monorepo-part-1/


# helm-charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![CircleCI](https://circleci.com/gh/kesterriley/helm-charts.svg?style=shield)](https://circleci.com/gh/kesterriley/helm-charts)



TO RELEASE you must update tag number in the chart.yaml


To build:
cd /Users/kester/src/github.com/kesterriley/helm-charts
rm -rf *.tgz
helm package charts/{kdr-maxscale,kdr-galera}
rm -rf index.yaml
helm repo index --url https://kesterriley.github.io/helm-charts/ .
git add .; git commit -m "Update to helm files";  git push origin master


To search repo:

helm search repo kdr

To refresh repo:

helm repo update

To add repo:

helm repo add kesterriley-repo https://kesterriley.github.io/helm-charts/


To remove repo:

helm repo remove kesterriley-repo



To install:

helm install kdr-galera kesterriley-repo/kdr-galera

To delete:

helm delete kdr-galera
