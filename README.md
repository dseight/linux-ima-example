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

## Required kernel configuration

All required kernel configuration options are already included in `config/linux-XXX`.
But if you want to configure kernel by yourself, take a look at following options:

    TODO

## More info

- [IMA/EVM (openSUSE support database)](https://en.opensuse.org/SDB:Ima_evm)
- [evmctl - IMA/EVM signing utility](http://linux-ima.sourceforge.net/evmctl.1.html)
- [Configuring Linux Kernel with QEMU guest support](https://wiki.gentoo.org/wiki/QEMU/Linux_guest)
