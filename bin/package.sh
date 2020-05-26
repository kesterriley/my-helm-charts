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


rm -rf .deploy
mkdir -p .deploy

helm repo index .deploy --url https://${CIRCLE_PROJECT_USERNAME}.github.io/${CIRCLE_PROJECT_REPONAME}

git config user.email "$GIT_EMAIL"
git config user.name "$GIT_USERNAME"

for file in charts/*/*.md; do
    if [[ -e $file ]]; then
        mkdir -p ".deploy/docs/$(dirname "$file")"
        cp --force "$file" ".deploy/docs/$(dirname "$file")"
    fi
done

git checkout gh-pages
cp --force .deploy/index.yaml index.yaml

if [[ -e ".deploy/docs/charts" ]]; then
    mkdir -p charts
    cp --force --recursive .deploy/docs/charts/* charts/
fi

git checkout master -- README.md

if ! git diff --quiet; then
    git add .
    git commit --message="Update index.yaml" --signoff
    git push "$GIT_REPOSITORY_URL" gh-pages
fi
