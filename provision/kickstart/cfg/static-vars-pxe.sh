hosts=(
    "127.0.0.1  nexus.soestack gateway  nexus"
    "10.10.10.101 infra.soestack infra    master"
)

NEXUS=127.0.0.1:7081/

repos=(
    "repo --name=os      --baseurl=http://$NEXUS/repository/centos/centos/\$releasever/os/\$basearch"
    "repo --name=updates --baseurl=http://$NEXUS/repository/centos/centos/\$releasever/updates/\$basearch"
)

# These vars are defaults which can be overridden
# by the boot-time kernel commandline.
SALT_TYPE=minion
SALT_MASTER=infra
DOMAIN=demo
NAMESERVER=gateway
ROLES=basic-node
LAYERS=soe:soestack,site:demo,lan:demo
DEVELOPMENT=1
INSPECT=1
WAIT=5
INTERACTIVE=1
SELINUX=permissive
TIMEZONE=UTC
HWCLOCK=UTC
BOOTSTRAP_REPOS=bootstrap-centos.repo

