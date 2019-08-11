hosts=(
    "192.168.121.1   gateway.demo.com gateway"
    "192.168.121.103 nexus.soestack nexus.demo.com nexus"
    "192.168.121.101 infra.soestack infra.demo.com infra    master"
)

# A standalone USB build will set up its own nexus repo

NEXUS=nexus:7081

repos=(
)

# These vars are defaults which can be overridden
# by the boot-time kernel commandline.
SALT_TYPE=master
SALT_MASTER=infra
DOMAIN=demo.com
NAMESERVER=gateway
ROLES=basic-node
LAYERS=soe:demo,site:testing,lan:example,private:example.private
DEVELOPMENT=0
SELINUX=permissive
TIMEZONE=UTC
HWCLOCK=UTC
#WAIT=1
BOOTSTRAP_REPOS=bootstrap-centos-usb.repo
REGISTRIES=nexus:7082,nexus:7083,nexus:7084,nexus:7085
