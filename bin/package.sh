#!/usr/bin/env bash

[[ -d /tmp/charts ]] || mkdir /tmp/charts

for chart in charts/*; do
  if [ $chart == 'charts/README.md' ]; then continue ; fi
  printf "\nChecking %s\n" "${chart#*/}"
  helm package ${chart} --destination /tmp/charts
done

git checkout gh-pages
run mv /tmp/charts/*.tgz .
run helm repo index . --url https://kesterriley.github.io/my-helm-charts
git add .
git commit -m "Publish charts"
git push origin gh-pages
