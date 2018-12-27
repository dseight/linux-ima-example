# Minimal Linux with IMA/EVM enabled

## Required packages

    build-essential bc flex libncurses5-dev ima-evm-utils openssl qemu-system-x86

## Build

    ./build.sh

There are certificate and key will be generated on the first build stage,
so you will be asked to type in some password.

Note: for somewhat reason, kernel does not accepts our dropped-in cert
on first build. To work around this, just run `./build.sh` twice.

## Run

    qemu-system-x86_64 \
        --nographic \
        --kernel out/bzImage \
        --drive file=out/system.img,if=virtio \
        --append "console=ttyS0 ima_appraise=enforce root=/dev/vda init=/init"

Any time you want to terminate QEMU, just press `Ctrl + A, X`.

As busybox is signed, IMA will not complain about it. You can try
to run some unsigned executable to see how it works, e.g:

    hello-unsigned

You may also run kernel with `ima_appraise=log`. This will allow you to run
any binaries (either signed or unsigned), and see messages in audit log
if binary was not signed.

You can improve boot speed by running QEMU with KVM support (use `--enable-kvm`
option). On my machine boot time halves down from 1.51 seconds to 0.78 seconds.

## Required kernel configuration

All required kernel configuration options are already included in
`config/linux-XXX`. But if you want to configure kernel by yourself from clean
configuration (e.g. `make allnoconfig`), take a look at following options.
Note that options should be enabled in the same order as here, as there are
some dependencies between them.

### Essential things to run kernel with image in QEMU

    [*] 64-bit kernel
    General setup --->
        [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
        -*- Configure standard kernel features (expert users)  --->
            [*] Enable support for printk
    Processor type and features  --->
        [*] Linux guest support  --->
            [*] Enable Paravirtualization code
            [*] KVM Guest support (including kvmclock)
    Bus options (PCI etc.)  --->
        [*] PCI support
    [*] Enable the block layer
    Executable file formats  --->
        [*] Kernel support for ELF binaries
        [*] Kernel support for scripts starting with #!
    Device Drivers  --->
        Generic Driver Options  --->
            [*] Maintain a devtmpfs filesystem to mount at /dev
            [*]   Automount devtmpfs at /dev, after the kernel mounted the rootfs
        Character devices  --->
            [*] Enable TTY
            Serial drivers  --->
                [*] 8250/16550 and compatible serial support
                [*]   Console on 8250/16550 and compatible serial port
        [*] Virtio drivers  --->
            [*] PCI driver for virtio devices
        [*] Block devices  --->
            [*] Virtio block driver
        SCSI device support  --->
            [*] SCSI low-level drivers  --->
                [*] virtio-scsi support
    File systems  --->
        [*] The Extended 4 (ext4) filesystem
        Pseudo filesystems  --->
            [*] /proc file system support
            [*] sysfs file system support

### Enable IMA support (with certificates)

    General setup  --->
        -*- Configure standard kernel features (expert users)  --->
            [*] Multiple users, groups and capabilities support
    [*] Enable loadable module support  --->
        [*] Module signature verification
    File systems  --->
        [*] The Extended 4 (ext4) filesystem
        [*]   Ext4 Security Labels
    Security options  --->
        [*] Enable different security models
        [*] Integrity subsystem
        [*]   Digital signature verification using multiple keyrings
        [*]     Enable asymmetric keys support
        [*]   Integrity Measurement Architecture(IMA)
                Default integrity hash algorithm (SHA256)
        [*]     Appraise integrity measurements
        [*]       ima_appraise boot parameter
        [*]   Load X509 certificate onto the '.ima' trusted keyring
        (/etc/keys/x509_ima.der) IMA X509 certificate path

### Enable IMA audit support

    [*] Networking support
    General setup  --->
        [*] Auditing support

## More info

- [IMA/EVM (openSUSE support database)](https://en.opensuse.org/SDB:Ima_evm)
- [evmctl - IMA/EVM signing utility](http://linux-ima.sourceforge.net/evmctl.1.html)
- [Configuring Linux Kernel with QEMU guest support](https://wiki.gentoo.org/wiki/QEMU/Linux_guest)
