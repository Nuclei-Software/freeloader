FREELOADER ?= freeloader.elf
ARCH ?= rv64imac
ABI ?= lp64

BUILD_ROOT ?= ../work
BOOT_MODE ?= sd

BOOTROM_BIN ?= $(BUILD_ROOT)/bootrom/bootrom.bin
FW_JUMP_BIN ?= $(BUILD_ROOT)/opensbi/platform/nuclei/ux600/firmware/fw_jump.bin
UBOOT_BIN ?= $(BUILD_ROOT)/u-boot/u-boot.bin
DTB ?= $(BUILD_ROOT)/boot/kernel.dtb
KERNEL_BIN ?= $(BUILD_ROOT)/boot/uImage.lz4
INITRD_BIN ?= $(BUILD_ROOT)/boot/uInitrd.lz4

CROSS_COMPILE ?= riscv-nuclei-linux-gnu-

FREELOADER_REQS := u-boot.bin bootrom.bin fw_jump.bin linker.lds freeloader.S fdt.dtb
CFLAGS := -g -march=$(ARCH) -mabi=$(ABI)

all: freeloader.bin freeloader.dis

bootrom.bin: $(BOOTROM_BIN)
	cp $< ./$@

u-boot.bin: $(UBOOT_BIN)
	cp $< ./$@

fw_jump.bin: $(FW_JUMP_BIN)
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

freeloader.bin: $(FREELOADER)
	$(CROSS_COMPILE)objcopy $< -O binary freeloader.bin

freeloader.dis: $(FREELOADER)
	$(CROSS_COMPILE)objdump -d $< > freeloader.dis

.PHONY: clean all

clean:
	rm -f *.bin
	rm -f *.elf
	rm -f *.dis
	rm -f freeloader
	rm -f *.dtb
