FREELOADER ?= freeloader.elf
ARCH ?= rv64imac
ABI ?= lp64

FW_JUMP_BIN ?= ../work/opensbi/platform/nuclei/ux600/firmware/fw_jump.bin
UBOOT_BIN ?= ../work/u-boot/u-boot.bin
DTB ?= ../work/u-boot/u-boot.dtb
CROSS_COMPILE ?= riscv-nuclei-elf-

all: freeloader.bin freeloader.dis

u-boot.bin: $(UBOOT_BIN)
	cp $< .

fw_jump.bin: $(FW_JUMP_BIN)
	cp $< .

fdt.dtb: $(DTB)
	cp $< ./$@

$(FREELOADER): u-boot.bin fw_jump.bin linker.lds freeloader.S fdt.dtb
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
