FREELOADER ?= freeloader.elf
ARCH ?= rv64imac
ABI ?= lp64

BUILD_ROOT ?= ../work
# BOOT_MODE supported : sd, flash
BOOT_MODE ?= sd

OPENSBI_BIN ?= $(BUILD_ROOT)/opensbi/platform/nuclei/demosoc/firmware/fw_jump.bin
UBOOT_BIN ?= $(BUILD_ROOT)/u-boot/u-boot.bin
DTB ?= $(BUILD_ROOT)/boot/kernel.dtb
KERNEL_BIN ?= $(BUILD_ROOT)/boot/uImage.lz4
INITRD_BIN ?= $(BUILD_ROOT)/boot/uInitrd.lz4

CROSS_COMPILE ?= riscv-nuclei-linux-gnu-
CFLAGS := -g -march=$(ARCH) -mabi=$(ABI)

FREELOADER_REQS := freeloader.S linker.lds
FREELOADER_REQS += u-boot.bin opensbi.bin fdt.dtb

all: freeloader.bin freeloader.dasm

u-boot.bin: $(UBOOT_BIN)
	cp $< ./$@

opensbi.bin: $(OPENSBI_BIN)
	cp $< ./$@

fdt.dtb: $(DTB)
	cp $< ./$@


ifeq ($(BOOT_MODE),flash)
FREELOADER_REQS += kernel.bin initrd.bin
CFLAGS += -DBOOT_MODE_FLASH

kernel.bin: $(KERNEL_BIN)
	cp $< ./$@

initrd.bin: $(INITRD_BIN)
	cp $< ./$@
endif

$(FREELOADER): $(FREELOADER_REQS)
	$(CROSS_COMPILE)gcc $(CFLAGS) freeloader.S -o $@ -nostartfiles -Tlinker.lds
	$(CROSS_COMPILE)size $@

freeloader.bin: $(FREELOADER)
	$(CROSS_COMPILE)objcopy $< -O binary freeloader.bin

freeloader.dasm: $(FREELOADER)
	$(CROSS_COMPILE)objdump -d $< > $@

.PHONY: clean all

clean:
	rm -f *.bin
	rm -f *.elf
	rm -f *.dasm
	rm -f *.dis
	rm -f *.dtb
