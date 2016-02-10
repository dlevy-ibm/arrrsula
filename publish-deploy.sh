#!/bin/bash

set -e

source project-list.sh

BASEDIR=$(pwd)/openstack

cd $BASEDIR
git push origin master

# Record the successful state into the repo that is good to pull from
for project in $LOCAL_PROJECTS ; do
    pushd $project
    git checkout -b deploymaybe
    git push pyrrrat HEAD:pyrrrat/deploy
    popd
done

git commit -a -m"Committing potential deploy state"
git checkout -b deploymaybe
git push origin HEAD:pyrrrat/deploy
