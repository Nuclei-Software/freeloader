OUTPUT_ARCH( "riscv" )

ENTRY( _start )

INCLUDE memory.lds

MEMORY
{
    /* current nuclei fpga emulation board's mcu spiflash size is only 4MB */
    /* but still put 32M here, for BOOT_MODE=flash to make build pass */
    flash (rxai!w) : ORIGIN = FLASH_BASE, LENGTH = FLASH_SIZE
}

SECTIONS
{

  .text :
  {
    KEEP (*(.text))

    . = ALIGN(8);
    KEEP (*(.bootrom))
    . = ALIGN(8);
    PROVIDE (_end_bootrom = .);

    . = ALIGN(8);
    KEEP (*(.sbipayload))
    . = ALIGN(8);
    PROVIDE (_end_sbi = .);

    KEEP (*(.ubootpayload))
    . = ALIGN(8);
    PROVIDE (_end_uboot = .);

    KEEP (*(.fdtpayload))
    . = ALIGN(8);
    PROVIDE (_end_fdt = .);

    KEEP (*(.ampfwpayloadc1))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc1 = .);

    KEEP (*(.ampfwpayloadc2))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc2 = .);

    KEEP (*(.ampfwpayloadc3))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc3 = .);

    KEEP (*(.ampfwpayloadc4))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc4 = .);

    KEEP (*(.ampfwpayloadc5))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc5 = .);

    KEEP (*(.ampfwpayloadc6))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc6 = .);

    KEEP (*(.ampfwpayloadc7))
    . = ALIGN(8);
    PROVIDE (_end_ampfwc7 = .);

    KEEP (*(.kernelpayload))
    . = ALIGN(8);
    PROVIDE (_end_kernel = .);

    KEEP (*(.initrdpayload))
    . = ALIGN(8);
    PROVIDE (_end_initrd = .);
  } >flash

}

