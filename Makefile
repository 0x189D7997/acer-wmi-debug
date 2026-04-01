obj-m := src/acer_wmi_debug.o

KVER  ?= $(shell uname -r)
KDIR  := /lib/modules/$(KVER)/build
PWD   := $(shell pwd)

MDIR  := /lib/modules/$(KVER)/kernel/drivers/platform/x86
MODNAME := acer_wmi_debug

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

	# --- auto sign block ---
	# Check if keys exist before attempting to sign
	@if [ -f "$(HOME)/module-signing/MOK.priv" ] && [ -f "$(HOME)/module-signing/MOK.der" ]; then \
	if [ -x "/lib/modules/$(KVER)/build/scripts/sign-file" ]; then \
	SIGN_TOOL="/lib/modules/$(KVER)/build/scripts/sign-file"; \
	elif [ -x "/usr/src/linux-headers-$(KVER)/scripts/sign-file" ]; then \
	SIGN_TOOL="/usr/src/linux-headers-$(KVER)/scripts/sign-file"; \
	else \
	echo "ERROR: sign-file tool not found, but MOK keys exist."; \
	exit 1; \
	fi; \
	echo "Signing module acer_wmi_debug.ko using $$SIGN_TOOL"; \
	sudo $$SIGN_TOOL sha256 \
	$(HOME)/module-signing/MOK.priv \
	$(HOME)/module-signing/MOK.der \
	$(PWD)/src/acer_wmi_debug.ko; \
	else \
	echo "MOK keys not found in ~/module-signing/. Skipping module signing (Common for non-Secure Boot)."; \
	fi
	# --- end auto sign block ---

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

uninstall:
	@sudo rm -f /etc/modules-load.d/$(MODNAME).conf
	@sudo rm -f /etc/modprobe.d/blacklist-acer_wmi.conf
	@sudo rmmod $(MODNAME) 2>/dev/null || true
	@sudo modprobe acer_wmi
	@sudo rm -f /etc/tmpfiles.d/$(MODNAME).conf
	@sudo rm -f $(MDIR)/$(MODNAME).ko
	@sudo depmod -a
	@echo "Uninstalled $(MODNAME) and cleaned up related configuration."

install: all
	@sudo rmmod acer_wmi 2>/dev/null || true
	@echo "blacklist acer_wmi" | sudo tee /etc/modprobe.d/blacklist-acer_wmi.conf > /dev/null
	sudo install -d $(MDIR)
	sudo install -m 644 src/$(MODNAME).ko $(MDIR)
	sudo depmod -a
	@echo "$(MODNAME)" | sudo tee /etc/modules-load.d/$(MODNAME).conf > /dev/null
	sudo modprobe $(MODNAME)
	@echo "Module $(MODNAME) installed."
