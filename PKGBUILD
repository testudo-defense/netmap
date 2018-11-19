# See http://wiki.archlinux.org/index.php/VCS_PKGBUILD_Guidelines
# for more information on packaging from GIT sources.

# Maintainer: Vincenzo Maffione <v.maffione@gmail.com>
pkgname=netmap
pkgver=r3882.88ad54aa
pkgrel=1
pkgdesc="A framework for high speed network packet I/O, using kernel bypass"
arch=('any')
url="http://info.iet.unipi.it/~luigi/netmap"
license=('BSD')
groups=()
depends=('glibc')
makedepends=('git' 'sed' 'gzip' 'linux-headers' 'pacman' 'xmlto' 'docbook-xsl' 'patch' 'bc' 'asp')
provides=()
conflicts=()
replaces=()
backup=()
options=()
install="netmap.install"
source=("netmap.install" "git+https://github.com/luigirizzo/netmap")
noextract=()
md5sums=("af2eb6608bdad77d58616f7ef91d3b26" "SKIP")

pkgver() {
        cd "$srcdir/${pkgname%-git}"
        printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
    readonly PKVER=$(pacman -Qi linux | grep Version | awk '{print $3}' | sed 's|\([1-9]\.[0-9]\+\).*|\1|g')
    readonly RKVER=$(uname -r | sed 's|\.[^.]*$||')
    if [ "$PKVER" != "$RKVER" ]; then
        msg "Pacman kernel version ($PKVER) differs from running kernel version ($RKVER)."
        msg "Please reboot the machine and try to rebuild this package."
        return 1
    fi

    # Fetch the kernel sources corresponding to the running kernel.
    msg "Downloading kernel sources (v${RKVER})..."
    cd $srcdir
    wget https://www.kernel.org/pub/linux/kernel/v${RKVER:0:1}.x/linux-${RKVER}.tar.gz
    tar xzf linux-${RKVER}.tar.gz

    # Prepare the kernel sources for building external modules.
    cd linux-${RKVER}
    readonly GCC_MAJOR_VERSION=$(echo '#include <stdio.h>
void main() { printf("%u\n", __GNUC__); }' | gcc -x c - -o /tmp/getgccversion  && /tmp/getgccversion)
    msg "GCC major version is ${GCC_MAJOR_VERSION}"
    compiler_file=compiler-gcc${GCC_MAJOR_VERSION}.h
    if [ ! -f include/linux/${compiler_file} -a ! -h include/linux/${compiler_file} ]
    then
        # Fix compilation of old kernels with recent GCC
        pushd include/linux
        if [ -f compiler-gcc5.h -a $GCC_MAJOR_VERSION -gt 5 ]
        then
            ln -sv compiler-gcc5.h ${compiler_file}
        else
            ln -sv compiler-gcc4.h ${compiler_file}
        fi
    popd
    fi
    make allmodconfig
    make modules_prepare
    msg "Kernel sources are ready"

    # Build the netmap kernel module and all modified drivers, using the
    # kernel sources downloaded in the previous steps to copy the NIC
    # drivers. Note however that the kernel modules are built against the
    # running kernel, and not against the downloaded sources.
    # We need to use --no-ext-drivers to make sure netmap does not
    # download (Intel) drivers sources from the internet, we want to use the
    # drivers sources provided by the Arch linux package.
    # We also build and install the patched drivers with a "-netmap" suffix,
    # so that they can be modprobed without conflicts/ambiguity with the
    # unpatched drivers
    msg "Starting to build netmap and netmap applications"
    cd "$srcdir/netmap"
    msg "PREFIX=$pkgdir/usr"
    msg "KERNEL_SOURCES=$srcdir/linux-${RKVER}"
    msg "INSTALL_MOD_PATH=$pkgdir"
    ./configure --kernel-sources="$srcdir/linux-${RKVER}" \
                --no-drivers=mlx5 \
                --driver-suffix="_netmap" \
                --install-mod-path="$pkgdir/usr" \
                --prefix="$pkgdir/usr"
    make
    msg "Build complete"
}

check() {
    cd "$srcdir/netmap"
    sudo rmmod netmap > /dev/null 2>&1 || true
    sudo insmod netmap.ko || insmod_failed="1"
    if [ -n "$insmod_failed" ]; then
        msg "Error: Cannot load netmap to run unit tests."
        msg "Please stop any running netmap applications or reboot the machine."
        return 1
    fi
    sudo make unitest
    sudo rmmod netmap
}

package() {
    cd "$srcdir/netmap"
    # Install netmap module, patched drivers modules, applications, headers
    # and the man page
    make install
    mv "$pkgdir/usr/bin/bridge" "$pkgdir/usr/bin/netmap-bridge"
    mv "$pkgdir/usr/bin/bridge-b" "$pkgdir/usr/bin/netmap-bridge-b"
}

# vim:set ts=2 sw=2 et:
