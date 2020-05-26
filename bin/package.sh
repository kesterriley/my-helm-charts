#!/usr/bin/env bash

# git config --global user.email "${CIRCLE_PROJECT_USERNAME}@users.noreply.github.com"
# git config --global user.name "${CIRCLE_PROJECT_USERNAME}"
set -o errexit
set -o nounset
set -o pipefail


: "${REPOSITORY_URL:?Environment variable GIT_REPO_URL must be set}"
: "${GIT_USERNAME:?Environment variable GIT_USERNAME must be set}"
: "${GIT_EMAIL:?Environment variable GIT_EMAIL must be set}"

helm init --client-only

mkdir -p /tmp/charts
cd /tmp/charts

git clone ${REPOSITORY_URL}

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

helm repo index . --url https://${CIRCLE_PROJECT_USERNAME}.github.io/${CIRCLE_PROJECT_REPONAME}

git config user.email "$GIT_EMAIL"
git config user.name "$GIT_USERNAME"

git checkout gh-pages

if ! git diff --quiet; then
    git add .
    git commit --message="Update index.yaml" --signoff
    git push "$GIT_REPOSITORY_URL" gh-pages
fi
