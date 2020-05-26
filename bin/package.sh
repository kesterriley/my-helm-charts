#!/usr/bin/env bash

[[ -f /tmp/charts ]] && mkdir -p /tmp/charts

for chart in charts/*
do
  echo $chart
  if [ $chart == 'charts/README.md' ]
  then
     continue
  fi
  printf "\nChecking %s\n" "${chart#*/}"
  helm package ${chart} --destination /tmp/charts
done

git checkout gh-pages
#mv /tmp/charts/*.tgz .
#helm repo index . --url https://kesterriley.github.io/my-helm-charts
#git add .
#git commit -m "Publish charts"
#git push origin gh-pages
ls -lar /tmp/charts
