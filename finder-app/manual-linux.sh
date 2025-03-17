#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$1
    echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
    # make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

echo "Creating directory for the root filesystem"
mkdir -p "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # make distclean
    # make defconfig
else
    cd busybox
fi

echo "Configuring and building BusyBox..."
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd "${OUTDIR}/rootfs"
echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
if [ -z "$SYSROOT" ]; then
    SYSROOT="/usr/aarch64-none-linux-gnu/libc"
fi
# SYSROOT="/usr/aarch64-none-linux-gnu/libc"
sudo cp -a "$SYSROOT/lib/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib/" || true
sudo cp -a "$SYSROOT/lib64/libm.so.6" "${OUTDIR}/rootfs/lib64/" || true
sudo cp -a "$SYSROOT/lib64/libc.so.6" "${OUTDIR}/rootfs/lib64/" || true
sudo cp -a "$SYSROOT/lib64/libresolv.so.2" "${OUTDIR}/rootfs/lib64/" || true
# make
# sudo mkdir -p ${OUTDIR}/rootfs/usr/bin
# sudo cp -a $(which make) ${OUTDIR}/rootfs/usr/bin/
# sudo cp -a $(which vim) ${OUTDIR}/rootfs/usr/bin/

# echo "Copying shared libraries..."
# for lib in $(ldd $(which make) | awk '{print $3}' | grep -v '^$'); do
#     sudo cp -a "$lib" "${OUTDIR}/rootfs/lib64/" || sudo cp -a "$lib" "${OUTDIR}/rootfs/lib/"
# done

# for lib in $(ldd $(which vim) | awk '{print $3}' | grep -v '^$'); do
#     sudo cp -a "$lib" "${OUTDIR}/rootfs/lib64/" || sudo cp -a "$lib" "${OUTDIR}/rootfs/lib/"
# done


# TODO: Make device nodes
echo "Creating device nodes"
cd "${OUTDIR}/rootfs"
sudo mknod -m 666 dev/null c 1 3 || true
sudo mknod -m 600 dev/console c 5 1 || true

# TODO: Clean and build the writer utility
echo "Building writer utility"
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

echo "Copying writer binary to rootfs /home"
cp writer "${OUTDIR}/rootfs/home/"

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copying finder scripts and config files to /home on target rootfs"
cp finder.sh       "${OUTDIR}/rootfs/home/"
cp finder-test.sh  "${OUTDIR}/rootfs/home/"

mkdir -p "${OUTDIR}/rootfs/home/conf"
cp conf/username.txt    "${OUTDIR}/rootfs/home/conf/"
cp conf/assignment.txt  "${OUTDIR}/rootfs/home/conf/"

# copy  autorun-qemu.sh  into  outdir/rootfs/home
cp autorun-qemu.sh "${OUTDIR}/rootfs/home/"

sed -i 's|\.\./conf/assignment.txt|conf/assignment.txt|g' "${OUTDIR}/rootfs/home/finder-test.sh"

sed -i '1s|/bin/bash|/bin/sh|' "${OUTDIR}/rootfs/home/finder.sh"
sed -i '1s|/bin/bash|/bin/sh|' "${OUTDIR}/rootfs/home/finder-test.sh"

# TODO: Chown the root directory
echo "Chowning the root directory to root:root"
cd "${OUTDIR}/rootfs"
sudo chown -R root:root .

# TODO: Create initramfs.cpio.gz
echo "Creating initramfs.cpio.gz"
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
cd "${OUTDIR}"
gzip -f initramfs.cpio

echo "All steps completed!"
echo "Kernel Image: ${OUTDIR}/Image"
echo "Initramfs:    ${OUTDIR}/initramfs.cpio.gz"
