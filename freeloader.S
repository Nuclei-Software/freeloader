/*
 * Copyright (C) 2020 Ruigang Wan <rgwan@nucleisys.com>
 * Copyright (C) 2021 Huaqi Fang <hqfang@nucleisys.com>
 * Copyright (C) 2020-present Nuclei System Technology
 */

#define DDR_BASE            0xA0000000

/* Max to 1MB */
#define OPENSBI_START_BASE  (DDR_BASE + 0x0)
/* Max to 14MB, offset to DDR_BASE 0x200000 - 0x400000 is reserved for uboot stack */
#define UBOOT_START_BASE    (DDR_BASE + 0x400000)
/* Offset to DDR_BASE: 0x1000000 - 0x8000000 */
#define KERNEL_START_BASE   (DDR_BASE + 0x1000000)
/* Offset to DDR_BASE: 0x8000000, Max to 1MB */
#define FDT_START_BASE      (DDR_BASE + 0x8000000)
/* Offset to DDR_BASE: 0x8100000, Max to 2MB */
#define COPY_START_BASE     (DDR_BASE + 0x8100000)
/* Offset to DDR_BASE: 0x8300000 - 0x10000000 */
#define INITRD_START_BASE   (DDR_BASE + 0x8300000)


#define CSR_MCACHE_CTL      0x7CA
#define CSR_CACHE_ENABLE    0x10001


.global _start
.section .text
_start:
    /* Enable I/D Cache */
    li t0, CSR_CACHE_ENABLE
    csrs CSR_MCACHE_CTL, t0

    /* Set exception entry */
    la t0, exc_entry
    csrw mtvec, t0

    /* move _copy_data() to DDR region */
    li t0, COPY_START_BASE
    la t1, _copy_data
    la t2, _copy_data + 4 * 8
    call _copy_data

    /* Flush cache after copy_data function copied to DDR */
    fence
    fence.i
    sfence.vma

    /* move data from NOR to DDR */
    li t0, OPENSBI_START_BASE
    la t1, sbi
    la t2, _end_sbi

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, 0(t3)

    /* U-Boot section */
    li t0, UBOOT_START_BASE
    la t1, uboot
    la t2, _end_uboot

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, 0(t3)

    /* FDT section */
    li t0, FDT_START_BASE
    la t1, fdt
    la t2, _end_fdt

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0

#ifdef BOOT_MODE_FLASH
    /* Kernel section */
    li t0, KERNEL_START_BASE
    la t1, kernel
    la t2, _end_kernel

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0

    /* Initrd section */
    li t0, INITRD_START_BASE
    la t1, initrd
    la t2, _end_initrd

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

    /* Flush cache */
    fence
    sfence.vma
    fence.i

    li a0, 0 /* hart ID */
    li a1, 0 /* fdt offset, reserved */
    li a2, 0 /* Reserved */

    /* Goto OpenSBI */

    li t0, OPENSBI_START_BASE
    jr t0

_deadloop:
    j .

/* Fall back to _start when exception happened */
.align 6
exc_entry:
    la a0, _start
    csrw mepc, a0
    mret

/* copy_data(void *dst, void *src, void *end) */
.align 4

_copy_data:
_loop:
    ld t3, 0(t1)
    sd t3, 0(t0)
    addi t0, t0, 8
    addi t1, t1, 8
    blt t1, t2, _loop
    ret

.section .sbipayload
.global sbi
.type sbi, @object
sbi:
.incbin "opensbi.bin"

.section .ubootpayload
.global uboot
.type uboot, @object
uboot:
.incbin "u-boot.bin"

.section .fdtpayload
.global fdt
.type fdt, @object
fdt:
.incbin "fdt.dtb"

#ifdef BOOT_MODE_FLASH
.section .kernelpayload
.global kernel
.type kernel, @object
kernel:
.incbin "kernel.bin"

.section .initrdpayload
.global initrd
.type initrd, @object
initrd:
.incbin "initrd.bin"
#endif