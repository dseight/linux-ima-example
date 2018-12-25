# Minimal Linux with IMA/EVM enabled

## Required packages

    build-essential bc cpio flex libncurses5-dev qemu-system-x86

## Build

    ./build.sh

## Run

    qemu-system-x86_64 \
        --nographic \
        --kernel out/bzImage \
        --initrd out/initramfs.cpio.gz \
        --append "console=ttyS0"

Any time you want to terminate QEMU, just press `Ctrl + A, X`.
