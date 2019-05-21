hosts=(
    "192.168.188.1   gateway.demo gateway"
    "192.168.121.103 nexus.soestack nexus.demo nexus"
    "192.168.121.101 infra.soestack infra.demo infra    master"
)

# A standalone USB build will set up its own nexus repo

NEXUS=http://nexus:7081/repository

repos=(
)

# These vars are defaults which can be overridden
# by the boot-time kernel commandline.
SALT_TYPE=master
SALT_MASTER=infra
DOMAIN=demo
NAMESERVER=gateway
ROLES=basic-node
LAYERS=soe:soestack,site:demo,lan:demo
DEVELOPMENT=1
SELINUX=permissive
TIMEZONE=UTC
HWCLOCK=UTC
#WAIT=1
BOOTSTRAP_REPOS=(bootstrap-centos.repo)
