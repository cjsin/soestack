#IMAGE        = boot-image.raw
IMAGE        = /dev/sdc
DEBUG        = 
VERBOSE      = 

#CONFIG       = bundler-dev.properties
#CONFIG       = bundler-usb.properties
CONFIG       = bundler-ultra-fit.properties
#CONFIG       = bundler-ultra-flair.properties
#CONFIG       = bundler-cruzer.properties

BUNDLER_HELP = ./ss-bundler.py $(CONFIG) --mode help
BUNDLER      = ./ss-bundler.py $(CONFIG) $(VERBOSE) --mode 
INSPECT      = ./build-boot-image.py --img $(IMAGE) inspect
CAT_SYSLINUX = --cat /usb/syslinux/syslinux.cfg
KS_FILES     = $(shell find ../kickstart -type f)

all: check

.phony: update check help


#help:########################
#help:## USB
#help:########################
#help:#boot-sector           # 
#help:#files                 #
#help:# |                    #
#help:# |syslinux            # - make menus
#help:# |   +syslinux.cfg    #
#help:# |                    #
#help:# |provision           # - make kickstarts
#help:#                      #
#help:# |bundled             #               \
#help:# |   +soe             #               |
#help:# |   +bootstrap-pkgs  #               |-- make bundle
#help:# |   +docker          #               |
#help:# |   +nexus           # - make nexus  /
#help:# |                    #
#help:# |iso                 # - make isos
#help:# |                    #
#help:# |Packages            # - make full
#help:# |                    #
#help:########################

#help:help        : display this help
help:
	@echo Makefile targets:
	@egrep '^#help:' Makefile | cut -d: -f2- | sed 's/^/  /' | tr ':' '\t'

#help:bundler-help: display bundler help
bundler-help:
	$(BUNDLER_HELP)

$(IMAGE):
	$(BUNDLER) create

#help:full        : prepare complete image
full: $(IMAGE)
	$(BUNDLER) full

#help:create      : synonym for full
create: $(IMAGE)
	$(BUNDLER) full

#help:bundle      : update bundled files
bundle: $(IMAGE) 
	$(BUNDLER) bundle

#help:update      : update image
update: $(IMAGE) 
	$(BUNDLER) update

#help:kickstarts  : update kickstart provisioning
kickstarts: $(IMAGE)
	$(BUNDLER) kickstarts

#help:nexus       : update nexus files
nexus: $(IMAGE)
	$(BUNDLER) nexus

#help:menus       : update syslinux menus
menus: $(IMAGE)
	$(BUNDLER) menus

#help:isos        : copy isos
isos: $(IMAGE) 
	$(BUNDLER) isos

#help:check       : print boot labels from the image
check: 
	$(INSPECT) $(CAT_SYSLINUX) | grep LABEL= | egrep -v 'rd.live|rescue|xdriver'

#help:conf        : print boot menus present in the image
conf:
	$(INSPECT) $(CAT_SYSLINUX)  | egrep . | egrep -i 'menu default|LABEL=|menu label'

#help:quick       : update the image in quick mode
quick: $(KS_FILES)
	$(BUNDLER) quick

