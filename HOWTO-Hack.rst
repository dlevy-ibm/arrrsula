Instructions for dealing with pyrrrat git repos
===============================================

If you need to make a local patch to a repo we have a fork of in pyrrrat,
just commit to its master branch.

If you need to make a local patch to a repo we do not have a fork of in
pyrrrat, make a fork of it in pyrrrat and make sure it's being managed
in clone-source.sh. Then just commit to its master branch.

OpenStack
---------

Just make commits to master. If the build breaks on a merge commit, clone
our master branch locally, then merge from upstream, then commit the merge
and push it to our master branch. For instance:

::
  git clone ssh://USER@review.portbleu.com:29418/nova
  cd nova
  git fetch https://git.openstack.org/openstack/nova
  git merge FETCH_HEAD
  git push origin

We do not make any attempt to do increasing versions, so feel free to rebase
and force push as we get patches landed upstream.

Open vSwitch
------------

Same as with OpenStack - but with one added note. We are using commits since
beginning of time as an artificial counter to make sure we can run upgrades
easily. This means *definitely* always merge with master and push - never
rebase and force-push because doing so will screw rev counts.

EXCEPT

If/when upstream increments their version - say from 2.5.90 to 2.5.91, if we're
all caught up with local patches, force-pushing a clean version of 2.5.91 to
our branch, even though the revcounter will get reset, is fine, because the
primary version number will have increased.

Using the scripts
=================

There are a set of scripts in this repo for the purposes of CI - but they are
also totally usable by humans.

clone-source.sh
---------------

Clones all of the source code into the `openstack` directory and applies any
of our local changes on top of it. Puts all of the repos into the correct state
and sets them onto a branch called `deploymaybe`.

install-builddeps.sh
--------------------

Installs packages needed on the build system to be able to build debs.

build-packages.sh
-----------------

Builds debian packages of the things that need them. Currently only builds
ovs. Packages will wind up in the `openstack` dir.

publish-deploy.sh
-----------------

After successful build/test, push the contents of the `deploymaybe` branch of
all of the repos back to github so that the deployment can fetch them.
