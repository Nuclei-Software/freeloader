FREELOADER ?= freeloader.elf
ARCH ?= rv64imac
ABI ?= lp64

BUILD_ROOT ?= ../build_nucleiv3

BOOTROM_BIN ?= $(BUILD_ROOT)/bootrom.build/bootrom.bin
FW_JUMP_BIN ?= $(BUILD_ROOT)/riscv-pk.build/bbl.bin
UBOOT_BIN ?= $(BUILD_ROOT)/u-boot.build/u-boot.bin
DTB ?= $(BUILD_ROOT)/boot.build/kernel.dtb
KERNEL_BIN ?= $(BUILD_ROOT)/boot.build/uImage.lz4
INITRD_BIN ?= $(BUILD_ROOT)/boot.build/uInitrd.lz4

CROSS_COMPILE ?= riscv64-unknown-linux-gnu-

all: freeloader.bin freeloader.dis

#bootrom.bin: $(BOOTROM_BIN)
#	cp $< ./@
#
#u-boot.bin: $(UBOOT_BIN)
#	cp $< ./@
#
#fw_jump.bin: $(FW_JUMP_BIN)
#	cp $< ./$@

kernel.bin: $(KERNEL_BIN)
	cp $< ./$@

initrd.bin: $(INITRD_BIN)
	cp $< ./$@

#fdt.dtb: $(DTB)
#	cp $< ./$@

$(FREELOADER): u-boot.bin bootrom.bin fw_jump.bin linker.lds freeloader.S fdt.dtb kernel.bin initrd.bin
	$(CROSS_COMPILE)gcc -g -march=$(ARCH) -mabi=$(ABI) freeloader.S -o $@ -nostartfiles -Tlinker.lds

freeloader.bin: $(FREELOADER)
	$(CROSS_COMPILE)objcopy $< -O binary freeloader.bin

freeloader.dis: $(FREELOADER)
	$(CROSS_COMPILE)objdump -d $< > freeloader.dis

.PHONY: clean all

clean:
	rm -f *.bin
	rm -f *.elf
	rm -f *.dis
	rm -f freeloader.bin
	rm -f freeloader
	rm -f *.dtb
