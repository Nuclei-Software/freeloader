/*
 * Copyright (C) 2020 Ruigang Wan <rgwan@nucleisys.com>
 * Copyright (C) 2021 Huaqi Fang <hqfang@nucleisys.com>
 * Copyright (C) 2020-present Nuclei System Technology
 */

#ifndef DDR_BASE
#define DDR_BASE            0xA0000000
#endif

/* Max to 1MB */
#define OPENSBI_START_BASE  (DDR_BASE + 0x0)
/* Max to 14MB */
#if __riscv_xlen == 32
#define UBOOT_START_BASE    (DDR_BASE + 0x400000)
#else
#define UBOOT_START_BASE    (DDR_BASE + 0x200000)
#endif
/* Offset to DDR_BASE: 0x3000000 - 0x8000000 */
#define KERNEL_START_BASE   (DDR_BASE + 0x3000000)
/* Offset to DDR_BASE: 0x8000000, Max to 1MB */
#define FDT_START_BASE      (DDR_BASE + 0x8000000)
/* Offset to DDR_BASE: 0x8100000, Max to 4KB */
#define COPY_START_BASE     (DDR_BASE + 0x8100000)
/* Offset to DDR_BASE: 0x0101000, between opensbi and uboot area */
#define BOOT_FLAG_BASE      (DDR_BASE + 0x0101000)
#define SMP_FLAG_BASE       (DDR_BASE + 0x0101004)
/* reserved 4 * 4 = 16 bytes, for core0 - core3 */
#define REBOOT_CNT_BASE     (DDR_BASE + 0x0101008)

/* Offset to DDR_BASE: 0x08300000 - 0xE0000000 */
#define INITRD_START_BASE   (DDR_BASE + 0x8300000)

/* Offset to DDR_BASE: the top area started @FIRMWARE_START_OFFSET is reserved for amp firmware */
#ifndef AMPFW_START_OFFSET
#define AMPFW_START_OFFSET  0xE000000
#endif
#ifndef AMPFW_SIZE
#define AMPFW_SIZE          (0x00400000)
#endif
#ifndef AMP_START_CORE
#define AMP_START_CORE      8
#endif


#define FIRMWARE_START_BASE (DDR_BASE + AMPFW_START_OFFSET)
/* reserved 8 cores firmware space, core1 - core7, each core 4M space */
#define AMPFW_START_BASE    (FIRMWARE_START_BASE + 0x0)

#define AMPFW_CORE_START_BASE(core)     (AMPFW_START_BASE + (AMPFW_SIZE * (core)))

#define AMPFW_C1_START_BASE AMPFW_CORE_START_BASE(0)
#define AMPFW_C2_START_BASE AMPFW_CORE_START_BASE(1)
#define AMPFW_C3_START_BASE AMPFW_CORE_START_BASE(2)
#define AMPFW_C4_START_BASE AMPFW_CORE_START_BASE(3)
#define AMPFW_C5_START_BASE AMPFW_CORE_START_BASE(4)
#define AMPFW_C6_START_BASE AMPFW_CORE_START_BASE(5)
#define AMPFW_C7_START_BASE AMPFW_CORE_START_BASE(6)

#define BOOT_FLAG_MAGIC     0xCAFE5A5AUL
#define BOOT_FLAG_COPY      0xFFA5A5FFUL

/* CSR macros */
#define CSR_MCACHE_CTL      0x7CA
#define CSR_MSMPCFG_INFO    0x7F7
#define CSR_IREGION_BASE    0x7F7
#define CSR_MCFG_INFO       0xFC2
#define CSR_MTLB_CTL        0x7DD
#define CSR_MMISC_CTL       0x7D0
#define CSR_MILM_CTL        0x7C0
#define CSR_MDLM_CTL        0x7C1
#define CSR_MMISC_CTL1      0x7E2


#ifndef CACHE_CTRL
/* ICache Enable, DCache Enable */
/* ICache Cache Enable, ICache Prefetch Enable, ICache Cancel Enable */
#define CSR_CACHE_ENABLE    0x100C1
#else
#define CSR_CACHE_ENABLE    CACHE_CTRL
#endif

#if __riscv_xlen == 64
#define LWU                 lwu
#else
#define LWU                 lw
#endif

.global _start
.section .text
_start:
    /* Disable interrupt */
    csrc mstatus, 0x8

#ifdef __riscv_vector
    /* enable rvv */
    li t1, 0x200
    csrs mstatus, t1
#endif

_get_smpbase:
#if (defined(ENABLE_SMP) && ENABLE_SMP == 1) || (defined(ENABLE_L2) && ENABLE_L2 == 1)
    /* If smp probe failed, goto _try_smp_fail,
     * directly skip steps to enable smp and l2 */
    lla t0, _try_smp_fail
    csrw mtvec, t0
    /* check whether iregion present */
    csrr t0, CSR_MCFG_INFO
    li t1, 0x10000
    and t0, t0, t1
    bne t0, zero, _get_iregion
    /* Enable L2 Cache using HART 0 */
    // get smp ctrl base to t0
    csrr t0, CSR_MSMPCFG_INFO
    srai t0, t0, 4 // t0 = t0 >> 4
    slli t0, t0, 4 // t0 = t0 << 4
    j _init
_get_iregion:
    /* get smp base from iregion base + smp offset */
    csrr t0, CSR_IREGION_BASE
    /* iregion base -> t0 */
    srai t0, t0, 10 // t0 = t0 >> 10
    slli t0, t0, 10 // t0 = t0 << 10
    // get iregion iinfo base address to t2
    li t1, 0x100
    add t2, t0, t1
    /* Init prefetch related registers, t2 = IINFO + 0x100 */

#ifdef SPFL1DCTRL1
    // set prefetch ctrl register spfl1dctrl1 bit[7:0], leave other bits rtl default
    lw t1, 0x0(t2)
    # t1 & (0xffffff00)
    andi t1, t1, -256
    ori t1, t1, SPFL1DCTRL1
    sw t1, 0x0(t2)
#endif
#if defined(SPFL1DCTRL1) && SPFL1DCTRL1 > 0
    // set spfl1dctrl4 prefetch overall switch bit[0] enabled
    lw t1, 0x24(t2)
    ori t1, t1, 0x1
    sw t1, 0x24(t2)
#endif
#ifdef SPFL1DCTRL2
    // set prefetch ctrl register spfl1dctrl2
    li t1, SPFL1DCTRL2
    sw t1, 0x4(t2)
#endif
#ifdef MERGL1DCTRL
    // set prefetch ctrl register mergl1dctrl
    li t1, MERGL1DCTRL
    sw t1, 0x8(t2)
#endif

    // get smp ctrl base to t0
    // iregion_base + 0x40000
    li t1, 0x40000
    add t0, t0, t1
#endif

_init:
    /* Don't use t0 here */
    /* Set exception entry */
    lla t1, exc_entry
    csrw mtvec, t1

_enable_smp:
#if defined(ENABLE_SMP) && ENABLE_SMP == 1
    // set smp enable = 0xFFFFFFFF, enable all core smp
    li t1, 0xFFFFFFFF
    sw t1, 0xc(t0)
    // make sure store sucessfully
    fence
#endif

_enable_l2:
#if defined(ENABLE_L2) && ENABLE_L2 == 1
    // set cluster cache way enable to 0
    // to make all cluster memory as l2 cache
    li t1, 0
    sw t1, 0xd8(t0)
    // set CC_EN = 0x1
    lw t1, 0x10(t0)
    ori t1, t1, 0x1
    sw t1, 0x10(t0)
    fence
#endif

_enable_l1:
    /* Enable Supervisor/User Mode CCM Operation */
    li t0, 0xFFFFFFFF
    csrw 0x7ce, t0
    /* Enable I/D Cache */
    li t0, CSR_CACHE_ENABLE
    csrs CSR_MCACHE_CTL, t0

_disable_ilm:
    /* check whether ilm present */
    csrr t0, CSR_MCFG_INFO
    li t1, 0x80
    and t0, t0, t1
    beq t0, zero, _disable_dlm
    /* disable ilm */
    li t0, 0x1
    csrc CSR_MILM_CTL, t0

_disable_dlm:
    /* check whether dlm present */
    csrr t0, CSR_MCFG_INFO
    li t1, 0x100
    and t0, t0, t1
    beq t0, zero, _check_hart
    /* disable dlm */
    li t0, 0x1
    csrc CSR_MDLM_CTL, t0

_check_hart:
#if defined(DDR_INIT) && DDR_INIT == 1
    /* internal use only for customsoc */
    li t0, 0x7fffff
    li t1, 0xf8b300020
    sw t0, 0(t1)
    li t1, 0xf8b300040
    sw t0, 0(t1)
#endif

    /* Hart 0 copy images, other hart wait copy finished, and jump to boot */
    csrr a0, mhartid
    beq a0, zero, _copy_image

_wait_copy:
    /* wait for some loops for flag cleared */
    li a0, 20000
    li a1, 0
    lla t0, _dead_loop_amp
    csrw mtvec, t0
_loop_wait:
    nop
    addi a1, a1, 1
    bne a0, a1, _loop_wait

    li t0, BOOT_FLAG_BASE
    LWU t0, 0(t0)
    li t1, BOOT_FLAG_MAGIC
    beq t0, t1, _start_smporamp
    j _wait_copy

_start_smporamp:
    csrr t0, mhartid
    li t1, AMP_START_CORE
    // branch to amp boot if amp start core >= hartid
    bgeu t0, t1, _start_amp
    j _start_boot

_start_amp:
    // Increase REBOOT_CNT_BASE + hartid * 4
    li t0, REBOOT_CNT_BASE
    csrr t2, mhartid
    li t1, 4
    mul t1, t1, t2
    add t0, t0, t1
    // * (REBOOT_CNT_BASE + hartid * 4) += 1
    LWU t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    fence

    // jump address t0 = AMPFW_START_BASE + AMPFW_SIZE * (mhartid - 1)
    li t0, AMPFW_START_BASE
    li t1, AMPFW_SIZE
    csrr t2, mhartid
    // mhartid must > 1 here
    addi t2, t2, -1
    // hart program offset = AMPfw_size * (hartid-1)
    mul t1, t1, t2
    add t0, t0, t1

    jr t0
    j _dead_loop_amp

_copy_image:
    /* Set boot_flag to 1 */
    li t0, BOOT_FLAG_BASE
    li t1, BOOT_FLAG_COPY
    sw t1, 0(t0)
    li t0, REBOOT_CNT_BASE
    // clear reboot count for 4 core to zero
    sw zero, 0(t0)
    sw zero, 4(t0)
    sw zero, 8(t0)
    sw zero, 16(t0)
    fence

    /* move _copy_data() to DDR region */
    li t0, COPY_START_BASE
    lla t1, _copy_data
    addi t2, t1, 32
    call _copy_data

    /* Flush cache after copy_data function copied to DDR */
    fence
    fence.i
    sfence.vma

    /* move data from NOR to DDR */
    li t0, OPENSBI_START_BASE
    lla t1, sbi
    lla t2, _end_sbi

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, 0(t3)

    /* U-Boot section */
    li t0, UBOOT_START_BASE
    lla t1, uboot
    lla t2, _end_uboot

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, 0(t3)

    /* FDT section */
    li t0, FDT_START_BASE
    lla t1, fdt
    lla t2, _end_fdt

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0

#if defined(WITH_AMPFW_CORE1)
    /* AMP Image Firmware section */
    li t0, AMPFW_C1_START_BASE
    lla t1, ampfwc1
    lla t2, _end_ampfwc1

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#if defined(WITH_AMPFW_CORE2)
    /* AMP Image Firmware section */
    li t0, AMPFW_C2_START_BASE
    lla t1, ampfwc2
    lla t2, _end_ampfwc2

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#if defined(WITH_AMPFW_CORE3)
    /* AMP Image Firmware section */
    li t0, AMPFW_C3_START_BASE
    lla t1, ampfwc3
    lla t2, _end_ampfwc3

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#if defined(WITH_AMPFW_CORE4)
    /* AMP Image Firmware section */
    li t0, AMPFW_C4_START_BASE
    lla t1, ampfwc4
    lla t2, _end_ampfwc4

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#if defined(WITH_AMPFW_CORE5)
    /* AMP Image Firmware section */
    li t0, AMPFW_C5_START_BASE
    lla t1, ampfwc5
    lla t2, _end_ampfwc5

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#if defined(WITH_AMPFW_CORE6)
    /* AMP Image Firmware section */
    li t0, AMPFW_C6_START_BASE
    lla t1, ampfwc6
    lla t2, _end_ampfwc6

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#if defined(WITH_AMPFW_CORE7)
    /* AMP Image Firmware section */
    li t0, AMPFW_C7_START_BASE
    lla t1, ampfwc7
    lla t2, _end_ampfwc7

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

#ifdef BOOT_MODE_FLASH
    /* Kernel section */
    li t0, KERNEL_START_BASE
    lla t1, kernel
    lla t2, _end_kernel

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0

    /* Initrd section */
    li t0, INITRD_START_BASE
    lla t1, initrd
    lla t2, _end_initrd

    /* call faraway function */
    li t3, COPY_START_BASE
    //call _copy_data
    jalr ra, t3, 0
#endif

    /* Flush cache */
    fence
    sfence.vma
    fence.i

_start_boot:
    /* Set mcache_ctl csr */
#ifdef MCACHE_CTL
    li a0, MCACHE_CTL
    csrw CSR_MCACHE_CTL, a0
#endif
    /* Set mtlb_ctl csr */
#ifdef MTLB_CTL
    li a0, MTLB_CTL
    csrw CSR_MTLB_CTL, a0
#endif
    /* Set mmisc_ctl csr */
#ifdef MMISC_CTL
    li a0, MMISC_CTL
    csrw CSR_MMISC_CTL, a0
#endif

    /* Enable BPU, since 2022.08, BPU is disabled on boot, need to set 1 when bringup */
    li a0, 0x8
    csrs CSR_MMISC_CTL, a0
#if defined(ENABLE_LDSPEC) && ENABLE_LDSPEC == 1
    /* Enable LDSPEC */
    li a0, 0x1000
    csrs CSR_MMISC_CTL, a0
#endif
    // should check region 4KB for vlsu_ooo in linux
    li a0, 0x2
    csrs CSR_MMISC_CTL1, a0
    /**
     * prepare opensbi entry arguments
     * hartid via a0 register
     * device tree blob address in memory via a1 register. The address must be aligned to 8 bytes.
     */
    csrr a0, mhartid /* hart ID */
    li a1, FDT_START_BASE /* fdt offset */
    li a2, 0 /* Reserved */

    /* clear boot_flag to 0 */
    li t0, BOOT_FLAG_BASE
    li t1, BOOT_FLAG_MAGIC
    sw t1, 0(t0)
    fence

    /* Goto OpenSBI */
    li t0, OPENSBI_START_BASE
    jr t0


/* copy_data(void *dst, void *src, void *end) */
.align 4
_copy_data:
_loop:
#if __riscv_xlen == 64
    ld t3, 0(t1)
    sd t3, 0(t0)
    addi t0, t0, 8
    addi t1, t1, 8
#else
    lw t3, 0(t1)
    sw t3, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 4
#endif
    blt t1, t2, _loop
    ret

/* Fall back to _start when exception happened */
.align 6
exc_entry:
    lla a0, _start
    csrw mepc, a0
    mret

/* Fall back to _enable_l1 when smp probe failed happened */
.align 6
_try_smp_fail:
    lla a0, _enable_l1
    csrw mepc, a0
    mret

.align 12
// dead loop, nop here
_dead_loop_amp:
_deadloop:
    // lla t0, _dead_loop_amp
    // csrw mtvec, t0
    csrc mstatus, 0x8
    li t0, CSR_CACHE_ENABLE
    csrc CSR_MCACHE_CTL, t0
    wfi
    j _deadloop

.section .sbipayload,"a"
.global sbi
.type sbi, @object
sbi:
.incbin "opensbi.bin"

.section .ubootpayload,"a"
.global uboot
.type uboot, @object
uboot:
.incbin "u-boot.bin"

.section .fdtpayload,"a"
.global fdt
.type fdt, @object
fdt:
.incbin "fdt.dtb"

#if defined(WITH_AMPFW_CORE1)
.section .ampfwpayloadc1,"a"
.global ampfwc1
.type ampfwc1, @object
ampfwc1:
.incbin "ampfw_core1.bin"
#endif

#if defined(WITH_AMPFW_CORE2)
.section .ampfwpayloadc2,"a"
.global ampfwc2
.type ampfwc2, @object
ampfwc2:
.incbin "ampfw_core2.bin"
#endif

#if defined(WITH_AMPFW_CORE3)
.section .ampfwpayloadc3,"a"
.global ampfwc3
.type ampfwc3, @object
ampfwc3:
.incbin "ampfw_core3.bin"
#endif

#if defined(WITH_AMPFW_CORE4)
.section .ampfwpayloadc4,"a"
.global ampfwc4
.type ampfwc4, @object
ampfwc4:
.incbin "ampfw_core4.bin"
#endif

#if defined(WITH_AMPFW_CORE5)
.section .ampfwpayloadc5,"a"
.global ampfwc5
.type ampfwc5, @object
ampfwc5:
.incbin "ampfw_core5.bin"
#endif

#if defined(WITH_AMPFW_CORE6)
.section .ampfwpayloadc6,"a"
.global ampfwc6
.type ampfwc6, @object
ampfwc6:
.incbin "ampfw_core6.bin"
#endif

#if defined(WITH_AMPFW_CORE7)
.section .ampfwpayloadc7,"a"
.global ampfwc7
.type ampfwc7, @object
ampfwc7:
.incbin "ampfw_core7.bin"
#endif

#ifdef BOOT_MODE_FLASH
.section .kernelpayload,"a"
.global kernel
.type kernel, @object
kernel:
.incbin "kernel.bin"

.section .initrdpayload,"a"
.global initrd
.type initrd, @object
initrd:
.incbin "initrd.bin"
#endif
