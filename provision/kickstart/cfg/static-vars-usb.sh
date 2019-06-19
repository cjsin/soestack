hosts=(
    "192.168.121.1   gateway.demo gateway"
    "192.168.121.103 nexus.soestack nexus.demo nexus"
    "192.168.121.101 infra.soestack infra.demo infra    master"
)

# A standalone USB build will set up its own nexus repo

NEXUS=nexus:7081

repos=(
)

# These vars are defaults which can be overridden
# by the boot-time kernel commandline.
SALT_TYPE=master
SALT_MASTER=infra
DOMAIN=demo
NAMESERVER=gateway
ROLES=basic-node
LAYERS=soe:soestack,site:testing,lan:demo
DEVELOPMENT=1
SELINUX=permissive
TIMEZONE=UTC
HWCLOCK=UTC
#WAIT=1
BOOTSTRAP_REPOS=bootstrap-centos.repo
