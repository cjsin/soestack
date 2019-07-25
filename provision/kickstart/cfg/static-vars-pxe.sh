hosts=(
    "127.0.0.1  nexus.soestack gateway  nexus"
    "10.10.10.101 infra.soestack infra    master"
)

NEXUS=nexus:7081/

repos=(
    "repo --name=os      --baseurl=http://$NEXUS/repository/centos/centos/\$releaselong/os/\$basearch"
    "repo --name=updates --baseurl=http://$NEXUS/repository/centos/centos/\$releaselong/updates/\$basearch"
)

# These vars are defaults which can be overridden
# by the boot-time kernel commandline.
SALT_TYPE=minion
SALT_MASTER=infra
DOMAIN=demo.com
NAMESERVER=gateway
ROLES=basic-node
LAYERS=soe:soestack,site:testing,lan:example,private:example.private
DEVELOPMENT=0
INSPECT=0
WAIT=0
INTERACTIVE=0
SELINUX=permissive
TIMEZONE=UTC
HWCLOCK=UTC
BOOTSTRAP_REPOS=bootstrap-centos.repo
DOCKER_REGISTRIES=nexus:7082,nexus:7083,nexus:7084,nexus:7085
DISABLE_REPOS=CentOS
