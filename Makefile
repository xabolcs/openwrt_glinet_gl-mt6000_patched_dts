# This Makefile downloads the OpenWrt ImageBuilder and patches
# the included tplink-safeloader to add more SupportList entries.
# Afterwards, the ImageBuilder can be used as normal.
#
# One advantage of this over from-source custom builds is that the 
# kernel is the same as the official builds, so all kmods from the 
# standard repos are installable.

ALL_CURL_OPTS := $(CURL_OPTS) -L --fail --create-dirs

VERSION ?= 23.05.0
BOARD := mediatek
SUBTARGET := filogic
ifeq ($(VERSION),SNAPSHOT)
	BUILDER := openwrt-imagebuilder-$(BOARD)-$(SUBTARGET).Linux-x86_64
	BUILDER_URL := https://downloads.openwrt.org/snapshots/targets/$(BOARD)/$(SUBTARGET)/$(BUILDER).tar.xz
else
	BUILDER := openwrt-imagebuilder-$(VERSION)-$(BOARD)-$(SUBTARGET).Linux-x86_64
	BUILDER_URL := https://downloads.openwrt.org/releases/$(VERSION)/targets/$(BOARD)/$(SUBTARGET)/$(BUILDER).tar.xz
endif
PROFILES := tplink_tl-wpa8630p-v2.0-eu tplink_tl-wpa8630p-v2.1-eu tplink_tl-wpa8630p-v2-int 
PACKAGES ?= luci wpad-basic luci-app-commands open-plc-utils-plctool open-plc-utils-plcrate open-plc-utils-hpavkeys -libustream-wolfssl -wpad-basic-wolfssl -ca-certificates -ppp -ppp-mod-pppoe -luci-proto-ppp
EXTRA_IMAGE_NAME := patch

BUILD_DIR := build
TOPDIR := $(CURDIR)/$(BUILD_DIR)/$(BUILDER)
KDIR := $(TOPDIR)/build_dir/target-aarch64_cortex-a53_musl/linux-$(BOARD)_$(SUBTARGET)
PATH := $(TOPDIR)/staging_dir/host/bin:$(PATH)
LINUX_VERSION = $(shell sed -n -e '/Linux-Version: / {s/Linux-Version: //p;q}' $(BUILD_DIR)/$(BUILDER)/.targetinfo)
OUTPUT_DIR := $(BUILD_DIR)/$(BUILDER)/bin/targets/$(BOARD)/$(SUBTARGET)


all: images


$(BUILD_DIR)/downloads/$(BUILDER).tar.xz:
	mkdir -p $(BUILD_DIR)/downloads
	cd $(BUILD_DIR)/downloads && curl $(ALL_CURL_OPTS) -O $(BUILDER_URL)
$(BUILD_DIR)/$(BUILDER): $(BUILD_DIR)/downloads/$(BUILDER).tar.xz
	cd $(BUILD_DIR) && tar -xf downloads/$(BUILDER).tar.xz
	
	# Apply all patches
	$(foreach file, $(sort $(wildcard patches/*.patch)), patch -d $(BUILD_DIR)/$(BUILDER) --posix -p1 < $(file);)
	
	# Build tools
	cd $(BUILD_DIR)/$(BUILDER) && ln -sf /usr/bin/cpp staging_dir/host/bin/aarch64-openwrt-linux-musl-cpp
	mkdir -p $(BUILD_DIR)/$(BUILDER)/tmp

$(BUILD_DIR)/$(BUILDER)/.targetinfo: $(BUILD_DIR)/linux-include $(BUILD_DIR)/$(BUILDER)
	# Regenerate .targetinfo
	touch -d 2023-12-31 $(BUILD_DIR)/$(BUILDER)/tmp/.packageauxvars
	cd $(BUILD_DIR)/$(BUILDER) && touch staging_dir/host/.prereq-build tmp/.config-feeds.in
	cd $(BUILD_DIR)/$(BUILDER) && make -f include/toplevel.mk TOPDIR="$(TOPDIR)" prepare-tmpinfo
	cd $(BUILD_DIR)/$(BUILDER) && cp -f tmp/.targetinfo .targetinfo


DTS_INCLUDE_DEPENDENCIES := \
	dt-bindings/clock/ath79-clk.h \
	dt-bindings/gpio/gpio.h \
	dt-bindings/input/input.h \

$(DTS_INCLUDE_DEPENDENCIES):
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/$@?h=v$(LINUX_VERSION)" -o $(KDIR)/linux-$(LINUX_VERSION)/include/$@

$(BUILD_DIR)/linux-include: $(BUILD_DIR)/$(BUILDER) $(DTS_INCLUDE_DEPENDENCIES)
	# Fetch DTS include dependencies
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/uapi/linux/input-event-codes.h?h=v$(LINUX_VERSION)" -o $(KDIR)/linux-$(LINUX_VERSION)/include/dt-bindings/input/linux-event-codes.h
	touch $(BUILD_DIR)/linux-include


images: $(BUILD_DIR)/$(BUILDER)/.targetinfo
	# Build this device's DTB and firmware kernel image. Uses the official kernel build as a base.
	cd $(BUILD_DIR)/$(BUILDER) && $(foreach PROFILE,$(PROFILES),\
	{\
		set -x;\
		export DTS_NAME=$$(echo $(PROFILE) | tr _ -);\
		export DEVICE_DTS=$$(find target/linux/mediatek/dts/ -name '*'$${DTS_NAME}.dts -exec basename {} .dts \; -quit);\
		env PATH=$(PATH) make --trace -C target/linux/$(BOARD)/image $(KDIR)/$(PROFILE)-kernel.bin TOPDIR="$(TOPDIR)" INCLUDE_DIR="$(TOPDIR)/include" TARGET_BUILD=1 BOARD="$(BOARD)" SUBTARGET="$(SUBTARGET)" PROFILE="$(PROFILE)" DEVICE_DTS="$${DEVICE_DTS}"\
	;})
	
	# Use ImageBuilder as normal
	cd $(BUILD_DIR)/$(BUILDER) && $(foreach PROFILE,$(PROFILES),\
	    make image PROFILE="$(PROFILE)" EXTRA_IMAGE_NAME="$(EXTRA_IMAGE_NAME)" PACKAGES="$(PACKAGES)" FILES="../../rootfs/"\
	;)
	cat $(OUTPUT_DIR)/sha256sums
	ls -hs $(OUTPUT_DIR)


clean:
	rm -rf build
