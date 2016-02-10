#!/bin/bash

set -e

source project-list.sh

git clone git@github.com:pyrrrat/openstack.git
BASEDIR=$(pwd)/openstack

cd $BASEDIR

# Update from upstream
git fetch https://git.openstack.org/openstack/openstack.git
git reset --hard FETCH_HEAD
git push origin master

# Null merge previous deploy branch changes if they exist
git branch -a | grep origin/pyrrrat/deploy && git merge -s ours -m 'Merging up with upstream' origin/pyrrrat/deploy

for project in $PURE_PROJECTS ; do
    git submodule update --init $project
done


for project in $LOCAL_PROJECTS ; do
    # Get the pure upstream version checked out
    git submodule update --init $project

    pushd $project

    # Fetch our repo state
    git remote add pyrrrat git@github.com:pyrrrat/${project}.git
    git remote update

    # If we already have a deploy branch, null merge it so we can just push
    git branch -a | grep pyrrrat/pyrrrat/deploy && git merge -s ours -m 'Merging up with upstream' pyrrrat/pyrrrat/deploy

    # Merge our change
    git fetch git@github.com:pyrrrat/${project}.git
    git merge --no-edit remotes/pyrrrat/master
    popd

    # Update the submodule to reference our repo
    git config -f .gitmodules submodule.${project}.url git@github.com:pyrrrat/${project}.git

done

# Get additional things
git submodule add https://github.com/openvswitch/ovs.git
git submodule add https://git.openstack.org/openstack/kuryr.git
git submodule add https://git.openstack.org/openstack/networking-ovn.git

echo You have sourcecode - you should test it!
