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
  } > flash

  /* above 8K is for zsbl code */
  . = ORIGIN(flash) + 0x2000;

  .payload . :
  {
    KEEP (*(.splpayload))
    KEEP (*(.spldtbpayload))
    . = ALIGN(8);
    PROVIDE (_end_spl = .);

    /* first 128K in payload is for uboot spl */
    . = 0x20000;
    KEEP (*(.splitbpayload))
    . = ALIGN(8);
    PROVIDE (_end_spl = .);

  } > flash

  /* above 1M is for zsbl + spl + spl itb code */
  . = ORIGIN(flash) + 0x100000;

  .ampfwpayload . :
  {
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
  } > flash
}

