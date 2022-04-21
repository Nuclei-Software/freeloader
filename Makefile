CROSS_COMPILE ?= riscv-nuclei-linux-gnu-
ARCH ?= rv64imac
ABI ?= lp64
ARCH_EXT ?=

SOC ?= demosoc
BUILD_ROOT ?= ../work/$(SOC)
# BOOT_MODE supported : sd, flash
BOOT_MODE ?= sd
O ?= build/$(SOC)

OPENSBI_BIN ?= $(BUILD_ROOT)/opensbi/platform/nuclei/$(SOC)/firmware/fw_jump.bin
UBOOT_BIN ?= $(BUILD_ROOT)/u-boot/u-boot.bin
DTB ?= $(BUILD_ROOT)/boot/kernel.dtb
KERNEL_BIN ?= $(BUILD_ROOT)/boot/uImage.lz4
INITRD_BIN ?= $(BUILD_ROOT)/boot/uInitrd.lz4
CORE1_APP_BIN ?=
CORE2_APP_BIN ?=
CORE3_APP_BIN ?=
CORE4_APP_BIN ?=
CORE5_APP_BIN ?=
CORE6_APP_BIN ?=
CORE7_APP_BIN ?=

# config makefile passed by make which defines
# DDR_BASE, FLASH_BASE, FLASH_SIZE, CACHE_CTRL
CONFIG_MK ?= ../conf/$(SOC)/freeloader.mk

-include $(CONFIG_MK)

DDR_BASE ?= 0xA0000000
FLASH_BASE ?= 0x20000000
FLASH_SIZE ?= 16M
CACHE_CTRL ?= 0x10001
ENABLE_SMP ?= 0
ENABLE_L2 ?= 0
AMP_START_CORE ?= 8

# Misc macros
check_item_exist = $(strip $(if $(filter 1, $(words $(1))),$(filter $(1), $(sort $(2))),))

# Internal variables
build_dir :=$(O)
FREELOADER := $(build_dir)/freeloader.elf
CONFIG_MK_REQ := $(wildcard $(CONFIG_MK))

CFLAGS := -g -march=$(ARCH)$(ARCH_EXT) -mabi=$(ABI)
CFLAGS += -DDDR_BASE=$(DDR_BASE) -DFLASH_BASE=$(FLASH_BASE) \
		-DFLASH_SIZE=$(FLASH_SIZE) -DCACHE_CTRL=$(CACHE_CTRL) \
		-DENABLE_SMP=$(ENABLE_SMP) -DENABLE_L2=$(ENABLE_L2) \
		-DAMP_START_CORE=$(AMP_START_CORE)

# memory.lds need to be the first requirement
FREELOADER_BUILD_REQS := memory.lds
FREELOADER_BUILD_REQS += u-boot.bin opensbi.bin fdt.dtb

all: $(build_dir)/freeloader.bin $(build_dir)/freeloader.dasm

$(build_dir)/u-boot.bin: $(UBOOT_BIN)
	cp $< $@

$(build_dir)/opensbi.bin: $(OPENSBI_BIN)
	cp $< $@

$(build_dir)/fdt.dtb: $(DTB)
	cp $< $@

# AMP Core Image binaries
ifneq ($(CORE1_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core1.bin
CFLAGS += -DWITH_AMPFW_CORE1
$(build_dir)/ampfw_core1.bin: $(CORE1_APP_BIN)
	cp $< $@
endif
ifneq ($(CORE2_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core2.bin
CFLAGS += -DWITH_AMPFW_CORE2
$(build_dir)/ampfw_core2.bin: $(CORE2_APP_BIN)
	cp $< $@
endif
ifneq ($(CORE3_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core3.bin
CFLAGS += -DWITH_AMPFW_CORE3
$(build_dir)/ampfw_core3.bin: $(CORE3_APP_BIN)
	cp $< $@
endif
ifneq ($(CORE4_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core4.bin
CFLAGS += -DWITH_AMPFW_CORE4
$(build_dir)/ampfw_core4.bin: $(CORE4_APP_BIN)
	cp $< $@
endif
ifneq ($(CORE5_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core5.bin
CFLAGS += -DWITH_AMPFW_CORE5
$(build_dir)/ampfw_core5.bin: $(CORE5_APP_BIN)
	cp $< $@
endif
ifneq ($(CORE6_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core6.bin
CFLAGS += -DWITH_AMPFW_CORE6
$(build_dir)/ampfw_core6.bin: $(CORE6_APP_BIN)
	cp $< $@
endif
ifneq ($(CORE7_APP_BIN),)
FREELOADER_BUILD_REQS += ampfw_core7.bin
CFLAGS += -DWITH_AMPFW_CORE7
$(build_dir)/ampfw_core7.bin: $(CORE7_APP_BIN)
	cp $< $@
endif

ifeq ($(BOOT_MODE),flash)
FREELOADER_BUILD_REQS += kernel.bin initrd.bin
CFLAGS += -DBOOT_MODE_FLASH

$(build_dir)/kernel.bin: $(KERNEL_BIN)
	cp $< $@

$(build_dir)/initrd.bin: $(INITRD_BIN)
	cp $< $@
endif

FREELOADER_REQS := $(addprefix $(build_dir)/, $(FREELOADER_BUILD_REQS)) freeloader.S linker.lds

$(FREELOADER): $(FREELOADER_REQS)
	$(CROSS_COMPILE)gcc $(CFLAGS) -I$(build_dir) freeloader.S -o $@ -nostartfiles \
		-L$(build_dir) -Wl,-M,-Map=$(build_dir)/freeloader.map -Tlinker.lds
	$(CROSS_COMPILE)size $@

$(build_dir)/memory.lds: $(CONFIG_MK_REQ)
	mkdir -p $(build_dir)
	echo "FLASH_BASE = $(FLASH_BASE);" > $@
	echo "FLASH_SIZE = $(FLASH_SIZE);" >> $@

$(build_dir)/freeloader.bin: $(FREELOADER)
	$(CROSS_COMPILE)objcopy $< -O binary $@

$(build_dir)/freeloader.dasm: $(FREELOADER)
	$(CROSS_COMPILE)objdump -d $< > $@

.PHONY: clean all

clean:
	rm -f $(build_dir)/*.bin
	rm -f $(build_dir)/*.elf
	rm -f $(build_dir)/*.dasm
	rm -f $(build_dir)/*.dis
	rm -f $(build_dir)/*.dtb
	rm -f $(build_dir)/*.map
	rm -f $(build_dir)/memory.lds
# always remove memory.lds located in source code folder
# to avoid link script using wrong memory.lds instead of the one
# existed in $(build_dir)/memory.lds
	rm -f memory.lds
