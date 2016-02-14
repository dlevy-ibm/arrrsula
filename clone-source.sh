#!/bin/bash

set -ex

source project-list.sh
BASEDIR=$(pwd)/openstack

if [ ! -d $BASEDIR ] ; then
    git clone git@github.com:pyrrrat/openstack.git
fi

cd $BASEDIR

# Update from upstream
git checkout master
git fetch https://git.openstack.org/openstack/openstack.git
git reset --hard FETCH_HEAD

# move git refs from gerrit to the git farm
for project in *; do
    git config -f .gitmodules submodule.${project}.url https://git.openstack.org/openstack/${project}
done
git commit -a -m"Moving all submodule refs to the git farm"


for project in $PURE_PROJECTS ; do
    git submodule update --init $project
done

# Get additional things
git submodule add https://github.com/openvswitch/ovs.git
git submodule add https://git.openstack.org/openstack/kuryr.git
git submodule add https://git.openstack.org/openstack/networking-ovn.git

for project in $LOCAL_PROJECTS ; do
    pushd $project
    git checkout master
    popd

    # Get the pure upstream version checked out
    git submodule update --init $project

    pushd $project

    # Fetch our repo state
    git remote | grep pyrrrat || git remote add pyrrrat git@github.com:pyrrrat/${project}.git
    git remote update

    # Merge our change
    git fetch git@github.com:pyrrrat/${project}.git
    git merge --no-edit remotes/pyrrrat/master

    git checkout -B deploymaybe
    popd

    # Update the submodule to reference our repo
    git config -f .gitmodules submodule.${project}.url git@github.com:pyrrrat/${project}.git

done

# Set up OVS for debian builds
pushd ovs
# Capture short sha for documentation purposes
OVS_REF=$(git rev-parse --short HEAD)
# Count of revisions - provides simple stupid method to keep our local debs
# monotonically increasing
OVS_REFCOUNT=$(git log --oneline | wc -l)
dch -l "${OVS_REFCOUNT}+git${OVS_REF}" -m "CI Build for ${OVS_REF}"
debcommit -a
popd

for project in $EXTRA_PROJECTS ; do
    pushd $project
    git fetch origin
    git reset --hard origin/master
    popd
done

git checkout -B deploymaybe
git commit -a -m"Committing potential deploy state"

echo You have sourcecode - you should test it!
