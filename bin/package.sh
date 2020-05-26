#!/usr/bin/env bash

git config --global user.email kesterriley@users.noreply.github.com
git config --global user.name Kester Riley

mkdir -p /tmp/charts
cd /tmp/charts

git clone https://github.com/kesterriley/my-helm-charts.git
cd /tmp/charts/my-helm-charts

for chart in charts/*
do
 if [ $chart == 'charts/README.md' ]
 then
    continue
 fi
 printf "\nChecking %s\n" "${chart#*/}"
 helm package ${chart} --destination .
done

git checkout gh-pages
helm repo index . --url https://kesterriley.github.io/my-helm-charts
git add .
git commit -m "Publish charts"
git push origin gh-pages
