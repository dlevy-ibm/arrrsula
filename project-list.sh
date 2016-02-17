# NOTE(mestery): Allow these to be overriden so we can set these in our jenkins jobs
PURE_PROJECTS=${PURE_PROJECTS:-'cinder glance heat horizon keystone neutron requirements'}
LOCAL_PROJECTS=${LOCAL_PROJECTS:-'nova python-ironicclient ironic ironic-python-agent ovs'}
EXTRA_PROJECTS=${EXTRA_PROJECTS:-'kuryr networking-ovn'}
