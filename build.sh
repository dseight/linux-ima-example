#!/bin/sh

KERNEL=linux-3.19.8
KERNEL_TAR=$KERNEL.tar.xz
BUSYBOX=busybox-1.29.3
BUSYBOX_TAR=$BUSYBOX.tar.bz2

BUILD_ROOT=$(pwd)

build_keys() {
    cd $BUILD_ROOT/keys
    if [ ! -f ima-local-ca.pem ]; then
        ./ima-gen-local-ca.sh
    fi
    if [ ! -f x509_ima.der ]; then
        ./ima-genkey.sh
    fi
}

build_kernel() {
    cd $BUILD_ROOT

    if [ ! -f $KERNEL_TAR ]; then
        wget https://cdn.kernel.org/pub/linux/kernel/v3.x/$KERNEL_TAR
    fi
    if [ ! -d $KERNEL ]; then
        tar xf $KERNEL_TAR
        cd $KERNEL
        patch -p1 < $BUILD_ROOT/0001-x86-asm-irq-Stop-relying-on-magic-JMP-behavior.patch
    fi

    cd $BUILD_ROOT
    cp config/$KERNEL-config $KERNEL/.config
    cp keys/ima-local-ca.x509 $KERNEL/signing_key.x509
    cp keys/ima-local-ca.priv $KERNEL/signing_key.priv
    cd $KERNEL
    make oldconfig
    make CC=gcc-4.8 -j8

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

build_ext4() {
    cd $BUILD_ROOT

    dd if=/dev/zero of=out/system.img bs=1M count=100
    sudo mkfs.ext4 out/system.img
    mkdir -p system
    sudo mount out/system.img system

    cd $BUILD_ROOT/$KERNEL
    sudo make modules_install INSTALL_MOD_PATH=$BUILD_ROOT/system

    cd $BUILD_ROOT/system
    sudo mkdir -vp dev bin sbin etc/keys proc sys tmp usr/bin usr/sbin
    sudo cp -a $BUILD_ROOT/$BUSYBOX/_install/* .
    sudo cp -a $BUILD_ROOT/prebuilt/* .

    cd $BUILD_ROOT

    # sign executables
    sudo evmctl ima_sign -a sha256 --key keys/privkey_ima.pem system/init
    sudo evmctl ima_sign -a sha256 --key keys/privkey_ima.pem system/bin/busybox

    # built x509 public key will be loaded into kernel keyring on boot
    sudo cp keys/x509_ima.der system/etc/keys/x509_ima.der

    sudo umount system
    rm -rf system
}

mkdir -p out
build_keys
build_kernel
build_busybox
build_ext4
