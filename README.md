![logo](./conf/logo.png)

# Starship SoC Generator

The `starship` is short for "**STA**rt **R**i**S**c-v on c**HIP**", hope this project will help you to learn how to run your own RISC-V design on FPGA boards.

Current support boards:
- Xilinx Virtex-7 VC707

This project is simple enough compared to *chipyard*. We will only focus on how to run the rocket processor cores on FPGAs and does not provide any simulation environment.

This project will provide great convenience for the following people who:
- ~~have Xilinx Virtex-7 VC707...~~ (I will try to support more boards!)
- want to test design on FPGA with modified rocket-chip
- want to have a overview about FPGA development

This project will follow the lastest rocket-chip, the functions of each folder in the project are as follows:
|       Folder        |      Description       | 
| :-----------------: | :--------------------: | 
|      firmware       | Zero&First Stage Bootloader |
|   repo/rocket-chip  | An in-order RISC-V core | 
|   repo/fpga-shell   |      FPGA Wrapper      | 
|   repo/sifive-block | Peripheral Components  | 
|    src/main/scala   | Top Module & Configuration |  



## Quickstart
> I only promise to you this project will work fine on ubuntu 20, vivado 2020.2.

Before you start compiling, you should already have sbt, vivado and a RISC-V toolchian.
```bash
$ git clone https://github.com/Phantom1003/riscv-starship.git
$ git submodule update --init --recursive --progress

# set $RISCV to your toolchain path, not inclued bin
$ make bitstream
```
After these, you will find your ditstream under `build/vivado/obj`, named `TestHarness.bit`.

You can open `build/vivado/TestHarness.xpr` to download your bitsream. But before you download the bitstream to the board, you should prepare the test program on a SD/TF card.
```bash
# Get your card number, replace x with your number
$ dmesg | tail
$ sudo sgdisk --clear \
      --new=1:2048:67583  --change-name=1:bootloader --typecode=1:2E54B353-1271-4842-806F-E436D6AF6985 \
      --new=2:264192:     --change-name=2:root       --typecode=2:0FC63DAF-8483-4772-8E79-3D69D8477DE4 \
      /dev/sdx
sudo dd if=<program> of=/dev/sdx1 bs=4096
sudo mke2fs -t ext3 /dev/sdx2
```
Now, start a terminal to catch the output from UART.
```
$ sudo screen -S FPGA /dev/ttyUSB0 115200
[FSBL] Starship SoC under 0000000002faf080 Hz
INIT
CMD0
CMD8
ACMD41
CMD58
CMD16
CMD18
LOADING
BOOT
bbl loader

[    0.000000] OF: fdt: Ignoring memory range 0x80000000 - 0x80200000
[    0.000000] Linux version 4.15.0-00048-gfe92d7905c6e (phantom0308@Pavilion) (gcc version 7.2.0 (GCC)) #1 SMP Sun Nov 10 22:55:16 CST 2019
[    0.000000] bootconsole [early0] enabled
[    0.000000] Initial ramdisk at: 0x        (ptrval) (9457664 bytes)
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080200000-0x00000000bfffffff]
[    0.000000]   Normal   [mem 0x00000000c0000000-0x00000bffffffffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080200000-0x00000000bfffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080200000-0x00000000bfffffff]
[    0.000000] software IO TLB [mem 0xbb1fd000-0xbf1fd000] (64MB) mapped at [        (ptrval)-        (ptrval)]
[    0.000000] elf_hwcap is 0x112d
[    0.000000] percpu: Embedded 14 pages/cpu @        (ptrval) s28632 r0 d28712 u57344
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 258055
[    0.000000] Kernel command line:
[    0.000000] Dentry cache hash table entries: 131072 (order: 8, 1048576 bytes)
[    0.000000] Inode-cache hash table entries: 65536 (order: 7, 524288 bytes)
[    0.000000] Sorting __ex_table...
[    0.000000] Memory: 950304K/1046528K available (3073K kernel code, 217K rwdata, 839K rodata, 9399K init, 780K bss, 96224K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] Hierarchical RCU implementation.
[    0.000000]  RCU event tracing is enabled.
[    0.000000]  RCU restricting CPUs from NR_CPUS=8 to nr_cpu_ids=1.
[    0.000000] RCU: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] riscv,cpu_intc,0: 64 local interrupts mapped
[    0.000000] riscv,plic0,c000000: mapped 2 interrupts to 1/2 handlers
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1d854df40, max_idle_ns: 3526361616960 ns
[    0.000135] sched_clock: 64 bits at 1000kHz, resolution 1000ns, wraps every 2199023255500ns
[    0.009144] Calibrating delay loop (skipped), value calculated using timer frequency.. 2.00 BogoMIPS (lpj=10000)
[    0.019234] pid_max: default: 32768 minimum: 301
[    0.026010] Mount-cache hash table entries: 2048 (order: 2, 16384 bytes)
[    0.032993] Mountpoint-cache hash table entries: 2048 (order: 2, 16384 bytes)
[    0.062612] Hierarchical SRCU implementation.
[    0.077804] smp: Bringing up secondary CPUs ...
[    0.081832] smp: Brought up 1 node, 1 CPU
[    0.093821] devtmpfs: initialized
[    0.115715] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.125582] futex hash table entries: 256 (order: 2, 16384 bytes)
[    0.139049] random: get_random_u32 called from bucket_table_alloc+0xe6/0x276 with crng_init=0
[    0.150137] NET: Registered protocol family 16
[    0.261707] vgaarb: loaded
[    0.269024] SCSI subsystem initialized
[    0.279939] usbcore: registered new interface driver usbfs
[    0.286085] usbcore: registered new interface driver hub
[    0.291816] usbcore: registered new device driver usb
[    0.298330] pps_core: LinuxPPS API ver. 1 registered
[    0.302743] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.312795] PTP clock support registered
[    0.327306] clocksource: Switched to clocksource riscv_clocksource
[    0.358706] NET: Registered protocol family 2
[    0.373497] TCP established hash table entries: 8192 (order: 4, 65536 bytes)
[    0.383928] TCP bind hash table entries: 8192 (order: 5, 131072 bytes)
[    0.394835] TCP: Hash tables configured (established 8192 bind 8192)
[    0.404988] UDP hash table entries: 512 (order: 2, 16384 bytes)
[    0.411598] UDP-Lite hash table entries: 512 (order: 2, 16384 bytes)
[    0.421384] NET: Registered protocol family 1
[    1.933183] Unpacking initramfs...
[    3.569930] Initialise system trusted keyrings
[    3.576173] workingset: timestamp_bits=62 max_order=18 bucket_order=0
[    3.722468] random: fast init done
[    3.786550] Key type asymmetric registered
[    3.790835] Asymmetric key parser 'x509' registered
[    3.795353] io scheduler noop registered
[    3.804001] io scheduler cfq registered (default)
[    3.808724] io scheduler mq-deadline registered
[    3.812679] io scheduler kyber registered
[    4.933819] Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
[    4.959765] 64000000.serial: ttySI0 at MMIO 0x64000000 (irq = 1, base_baud = 0) is a sifive-serial
[    4.968876] console [ttySI0] enabled
[    4.968876] console [ttySI0] enabled
[    4.975431] bootconsole [early0] disabled
[    4.975431] bootconsole [early0] disabled
[    5.003025] sifive_spi 64001000.spi: mapped; irq=2, cs=1
[    5.019172] libphy: Fixed MDIO Bus: probed
[    5.027294] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    5.033279] ehci-pci: EHCI PCI platform driver
[    5.040187] usbcore: registered new interface driver usb-storage
[    5.107312] mmc_spi spi0.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[    5.119092] usbcore: registered new interface driver usbhid
[    5.124095] usbhid: USB HID core driver
[    5.133172] NET: Registered protocol family 17
[    5.153372] Loading compiled-in X.509 certificates
[    5.424975] Freeing unused kernel memory: 9396K
[    5.429294] This architecture does not have kernel memory protection.
[    5.583550] mmc0: host does not support reading read-only switch, assuming write-enable
[    5.591954] mmc0: new SDHC card on SPI
[    5.617670] mmcblk0: mmc0:0000 SE32G 29.7 GiB
[    5.942567]  mmcblk0: p1 p2
Starting logging: OK
Starting mdev...
sort: /sys/devices/platform/Fixed: No such file or directory
modprobe: can't change directory to '/lib/modules': No such file or directory
Initializing random number generator... done.
Starting network...
Waiting for interface eth0 to appear............... timeout!
run-parts: /etc/network/if-pre-up.d/wait_iface: exit status 1
Starting dropbear sshd: OK

Welcome to Buildroot
buildroot login: root
Password:
# cat /proc/cpuinfo
hart    : 0
isa     : rv64imafdc
mmu     : sv39
uarch   : sifive,rocket0

# uname -a
Linux buildroot 4.15.0-00048-gfe92d7905c6e #1 SMP Sun Nov 10 22:55:16 CST 2019 riscv64 GNU/Linux
# mount /dev/mmcblk0p2 /mnt
[ 1043.200937] EXT4-fs (mmcblk0p2): mounting ext3 file system using the ext4 subsystem
[ 1043.725533] EXT4-fs (mmcblk0p2): mounted filesystem with ordered data mode. Opts: (null)
# chroot /mnt/riscv64-chroot/ /bin/bash -l
root@buildroot:/# cat /etc/debian_version
bullseye/sid
root@buildroot:/# logout
# poweroff
# Stopping dropbear sshd: OK
Stopping network...ifdown: interface eth0 not configured
Saving random seed... done.
Stopping logging: OK
umount: can't unmount /: Invalid argument
The system is going down NOW!
Sent SIGTERM to all processes
Sent SIGKILL to all processes
Requesting system poweroff
[ 1230.263390] reboot: Power down
Power off
```

Finally, if you have any suggestions for this project, please *push* it !