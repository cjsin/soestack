DEBUG        = 
VERBOSE      = 

IMAGE        ?= images/boot-image.qcow2
#IMAGE       ?= /dev/sdc
USB_NAME     ?= image-file
#USB_NAME    ?= usb-example-device

CONFIG       := bundler-$(USB_NAME).properties

BUNDLER_HELP = ./ss-bundler.py $(CONFIG) --mode help
BUNDLER      = ./ss-bundler.py $(CONFIG) $(VERBOSE) --mode 
INSPECT      = ./build-boot-image.py --img $(IMAGE) inspect
CAT_SYSLINUX = --cat /usb/syslinux/syslinux.cfg
KS_FILES     = $(shell find ../kickstart -type f)

.PHONY: all help bundler-help full create bundle update kickstarts nexus check soe isos menus conf quick

all:
	@echo "Running with the following settings:"
	@echo "    IMAGE    = $(IMAGE)"
	@echo "    USB_NAME = $(USB_NAME)"
	@echo "    CONFIG   = $(CONFIG)"
	@echo
	@make help

#help:##
#help:# Example usage:
#help:##
#help:#
#help:#  building a physical USB:
#help:#      make USB_NAME=example-device IMAGE=/dev/sdc
#help:#  building an image file:
#help:#      make USB_NAME=image-file IMAGE=images/boot-image.qcow2
#help:#
#help:

#help:############################ 
#help:## USB                     # Make target
#help:############################
#help:# boot-sector              # ----------------\
#help:# partitioning             #                  |
#help:# files                    #                  |
#help:#   _                      #                  |
#help:#  | |provision/           # \ kickstarts     |
#help:#  |_|ks.cfg               # /                |
#help:#   _                      #                  |
#help:#  | |bundled/             #                  |
#help:#  | |  _   _              #                  |
#help:#  | | | | |_| soe/        # - soe \          |
#help:#  | | | | bootstrap-pkgs/ #       |-- bundle |
#help:#  | | |_| docker/         #       /          |
#help:#  |_| |_| nexus/          # - nexus          |-- full
#help:#   _                      #                  |
#help:#  |_|isos/                # - isos           |
#help:#   _                      #                  |
#help:#  | |Packages/            #                  |
#help:#  | |repodata/            #                  |
#help:#  | |images/              #                  |
#help:#  | |EFI/                 #                  |
#help:#  | |isolinux/            #                  |
#help:#  | |syslinux/            #                  |
#help:#  | |  _                  #                  |
#help:#  |_| |_| syslinux.cfg    # - menus          |
#help:#                          # ----------------/
#help:############################

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
full:
	$(BUNDLER) full

#help:create      : synonym for full
create:
	$(BUNDLER) full

#help:bundle      : update bundled files
bundle:
	$(BUNDLER) bundle

#help:update      : update image
update:
	$(BUNDLER) update

#help:kickstarts  : update kickstart provisioning
kickstarts:
	$(BUNDLER) kickstarts

#help:nexus       : update nexus files
nexus:
	$(BUNDLER) nexus

#help:menus       : update syslinux menus
menus:
	$(BUNDLER) menus

#help:soe         : update bundled soe code copy
soe:
	$(BUNDLER) soe

#help:isos        : copy isos
isos:
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
