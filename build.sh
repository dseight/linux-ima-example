#!/bin/sh

KERNEL=linux-4.19.12
KERNEL_TAR=$KERNEL.tar.xz
BUSYBOX=busybox-1.29.3
BUSYBOX_TAR=$BUSYBOX.tar.bz2

BUILD_ROOT=$(pwd)

build_kernel() {
    cd $BUILD_ROOT

    if [ ! -f $KERNEL_TAR ]; then
        wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$KERNEL_TAR
    fi
    if [ ! -d $KERNEL ]; then
        tar xf $KERNEL_TAR
    fi

    cp config/$KERNEL-config $KERNEL/.config
    cd $KERNEL
    make oldconfig
    make -j8

    cp arch/x86/boot/bzImage $BUILD_ROOT/out/bzImage
}

build_busybox() {
    cd $BUILD_ROOT

    if [ ! -f $BUSYBOX_TAR ]; then
        wget https://busybox.net/downloads/$BUSYBOX_TAR
    fi
    if [ ! -d $BUSYBOX ]; then
        tar xf $BUSYBOX_TAR
    fi
    
    cp config/$BUSYBOX-config $BUSYBOX/.config
    cd $BUSYBOX
    make oldconfig
    make -j8
    # Do not afraid, it will do install into a local directory (_install)
    make install
}

build_initramfs() {
    rm -rf $BUILD_ROOT/initramfs
    mkdir -vp $BUILD_ROOT/initramfs

    cd $BUILD_ROOT/$KERNEL
    make modules_install INSTALL_MOD_PATH=$BUILD_ROOT/initramfs

    cd $BUILD_ROOT/initramfs
    mkdir -vp bin sbin etc proc sys usr/bin usr/sbin
    cp -a $BUILD_ROOT/$BUSYBOX/_install/* .
    cp -a $BUILD_ROOT/prebuilt/* .

    find . -print0 | cpio --null -ov --format=newc | gzip -9 \
        > $BUILD_ROOT/out/initramfs.cpio.gz
}

mkdir -p out
build_kernel
build_busybox
build_initramfs
