This repository contains freeloader, which can load OpenSBI image and U-Boot image to Nuclei Demo SoC
running on Nuclei FPGA Evaluation Board, DDR200T variant.

**BOOT_MODE**:

`BOOT_MODE` variable is used to control freeloader booting mode.

* **sd**: default, boot from spiflash and sdcard, spiflash contains loader, opensbi, uboot, and dtb.
  SDCard contains kernel, rootfs, dtb, and uboot cmd.
* **flash**: boot from spiflash only, spiflash contains loader, opensbi, uboot, rootfs, dtb.
  No need for sdcard, flash size need to be bigger. Current flash size defined in link script file is 16M.

**CONFIG_MK**:

You can pass `CONFIG_MK` variable to make, and it is used to pass freeloader config makefile. eg.

~~~makefile
DDR_BASE ?= 0xA0000000
FLASH_BASE ?= 0x20000000
FLASH_SIZE ?= 16M
CACHE_CTRL ?= 0x10001
~~~

**Memory Layout**:

See [freeloader.S](freeloader.S#L11-L22)


**Authors**:

* Ruigang Wan <rgwan@nucleisys.com>
* Huaqi Fang <hqfang@nucleisys.com>
