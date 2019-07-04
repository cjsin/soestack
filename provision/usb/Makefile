DEBUG           = 
VERBOSE         = 

# The variables IMAGE, USB_NAME, and LAN_NAME are mandatory
# and are left empty so that the user needs to specify them
# explicitly on the commandline or environment (unless they edit them in here)

IMAGE           ?=
#IMAGE           ?= images/boot-image.qcow2
#IMAGE           ?= /dev/sdc

USB_NAME        ?=
#USB_NAME        ?= image-file
#USB_NAME        ?= usb-example-device

LAN_NAME        ?= 
#LAN_NAME        ?= usb-vm

ifeq ($(USB_NAME),)
$(error Mandatory variable USB_NAME was not specified. Please specify it on the commandline.)
endif
ifeq ($(LAN_NAME),)
$(error Mandatory variable LAN_NAME was not specified. Please specify it on the commandline.)
endif
ifeq ($(IMAGE),)
$(error Mandatory variable IMAGE was not specified. Please specify it on the commandline.)
endif

#__check_defined = $(if $(value $1), , $(error Undefined mandatory variable $1 - Please specify it on the commandline $(if $2, ( : $2))))
#$(call __check_defined, USB_NAME)
#$(call __check_defined, LAN_NAME)
#$(call __check_defined, IMAGE)

CONFIG          := bundler-$(USB_NAME).properties

# This should ideally match your libguestfs version
GUESTFS_VERSION = 1.40.2
GUESTFS_ARCHIVE = guestfs-$(GUESTFS_VERSION).tar.gz
GUESTFS_SRC     = http://libguestfs.org/download/python/$(GUESTFS_ARCHIVE)
GUESTFS_HEADER  = /usr/include/guestfs.h
ACTIVATE        = . venv/bin/activate
VENV_PIP        = $(ACTIVATE) && pip

BUNDLER_SCRIPT  = ./ss-bundler.py 
BUNDLER_HELP    = $(ACTIVATE) && $(BUNDLER_SCRIPT) $(CONFIG) --mode help
BUNDLER         = $(ACTIVATE) && $(BUNDLER_SCRIPT) $(CONFIG) $(VERBOSE) --mode 
INSPECT         = $(ACTIVATE) && ./build-boot-image.py --img $(IMAGE) inspect

CAT_SYSLINUX    = --cat /usb/syslinux/syslinux.cfg
KS_FILES        = $(shell find ../kickstart -type f)

BUNDLER_GEN     = bundler-$(LAN_NAME).properties

BUNDLER_FILES   = bundler-usb.properties \
					bundler-usb-defaults.properties \
					bundler-base.properties \
					$(BUNDLER_GEN)

GENERATED       = $(BUNDLER_GEN) venv

.PHONY: all \
		help bundler-help info \
		full create bundle update provision nexus check soe isos menus conf quick htdocs private \
		venv check-requirements

all: help

info:
	@echo "Running with the following settings:"
	@echo "    IMAGE    = $(IMAGE)"
	@echo "    USB_NAME = $(USB_NAME)"
	@echo "    LAN_NAME = $(LAN_NAME)"
	@echo "    CONFIG   = $(CONFIG)"

#help:##
#help:# Example usage:
#help:##
#help:#
#help:#  building a physical USB:
#help:#      make USB_NAME=usb-example-device IMAGE=/dev/sdc
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
#help:#  | |provision/           # \ provision      |
#help:#  |_|ks.cfg               # /                |
#help:#   _                      #                  |
#help:#  | |bundled/             #                  |
#help:#  | |  _   _              #                  |
#help:#  | | | | |_| soe/        # - soe \          |
#help:#  | | | | bootstrap-pkgs/ #       |-- bundle |
#help:#  | | |_| docker/         #       /          |
#help:#  |_| |_| nexus/          # - nexus          |-- full
#help:#   _                      #                  |
#help:#  |_| htdocs/             #                  |
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
help: info
	@echo Makefile targets:
	@egrep '^#help:' Makefile | cut -d: -f2- | sed 's/^/  /' | tr ':' '\t'
	# Display the build info again at the bottom
	@make info
	@make system-requirements

#help:bundler-help: display bundler help
bundler-help:
	$(BUNDLER_HELP)

$(IMAGE): $(GENERATED)
	$(BUNDLER) create

#help:full        : prepare complete image
full: $(GENERATED)
	$(BUNDLER) full

#help:create      : synonym for full
create: $(GENERATED)
	$(BUNDLER) full

#help:bundle      : update bundled files
bundle: $(GENERATED)
	$(BUNDLER) bundle

#help:update      : update image
update: $(GENERATED)
	$(BUNDLER) update

#help:provision   : update kickstart provisioning
provision: $(GENERATED)
	$(BUNDLER) provision

#help:nexus       : update nexus files
nexus: $(GENERATED)
	$(BUNDLER) nexus

#help:menus       : update syslinux menus
menus: $(GENERATED)
	$(BUNDLER) menus

#help:soe         : update bundled soe code copy
soe: $(GENERATED)
	$(BUNDLER) soe

#help:htdocs      : copy the generated html docs
htdocs: $(GENERATED)
	$(BUNDLER) htdocs

#help:isos        : copy isos
isos: $(GENERATED)
	$(BUNDLER) isos

#help:check       : print boot labels from the image
check: $(GENERATED)
	$(INSPECT) $(CAT_SYSLINUX) | grep LABEL= | egrep -v 'rd.live|rescue|xdriver'

#help:conf        : print boot menus present in the image
conf: $(GENERATED)
	$(INSPECT) $(CAT_SYSLINUX)  | egrep . | egrep -i 'menu default|LABEL=|menu label'

#help:quick       : update the image in quick mode
quick: $(KS_FILES) $(GENERATED)
	$(BUNDLER) quick

#help:private     : copy the private files (a directory of gitignored private local files)
private: $(GENERATED)
	$(BUNDLER) private

## Choose bundler-usb-vm or bundler-usb-sv depending on USB_LAN
$(BUNDLER_GEN): bundler-$(LAN_NAME).properties
	cp -f $< $@

$(GUESTFS_ARCHIVE):
	wget $(GUESTFS_SRC)

system-requirements:
	@command -v python3 > /dev/null 2> /dev/null || ( echo "MISSING: python3 is not available" 1>&2 ; /bin/false )
	@echo "PASS: $@ - python3"
	@test -f $(GUESTFS_HEADER) || ( echo "ERROR: Guestfs devel headers are not installed!" 1>&2; /bin/false )
	@echo "PASS: $@ - guestfs devel headers"

venv-install:
	@test -d venv || python3 -m venv venv
	@$(VENV_PIP) install --upgrade pip
	@$(VENV_PIP) list | grep attrdict || $(VENV_PIP) install attrdict
	@$(VENV_PIP) list | grep guestfs  || $(VENV_PIP) install $(GUESTFS_ARCHIVE)
	@echo "Pip packages installed:"
	@$(VENV_PIP) list 

venv-requirements:
	@$(VENV_PIP) list | egrep -c 'attrdict|guestfs' | egrep -q '^2$$' || make venv-install || /bin/false
	@echo "PASS: $@"

venv: $(GUESTFS_ARCHIVE) system-requirements venv-requirements
