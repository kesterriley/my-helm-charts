#!/usr/bin/env bash

# git config --global user.email "${CIRCLE_PROJECT_USERNAME}@users.noreply.github.com"
# git config --global user.name "${CIRCLE_PROJECT_USERNAME}"

git config user.email "kesterriley@users.noreply.github.com"
git config user.name "Kester Riley"


helm init --client-only



mkdir -p /tmp/charts
cd /tmp/charts

git clone ${REPOSITORY_URL}

cd /tmp/charts/my-helm-charts

git checkout ExpertAdvice


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
helm repo index . --url https://${CIRCLE_PROJECT_USERNAME}.github.io/${CIRCLE_PROJECT_REPONAME}
git add .
git commit -m "Publish charts"

cat ~/.gitconfig

git push origin gh-pages
