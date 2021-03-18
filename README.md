This repository contains freeloader, which can load OpenSBI image and U-Boot image to Nuclei Demo SoC running on Nuclei HummingBird FPGA Evaluation Board, DDR200T variant.

**BOOT_MODE supported:**

* sd: default, boot from spiflash and sdcard, spiflash contains loader, opensbi, uboot, and dtb, sdcard contains kernel, rootfs, dtb, and uboot cmd.
* flash: boot from spiflash only, spiflash contains loader, opensbi, uboot, rootfs, dtb, No need for sdcard, flash size need to be bigger. Current flash size defined in link script file is 32M.

Ruigang Wan <rgwan@nucleisys.com>
