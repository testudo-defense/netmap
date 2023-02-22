FROM ocaml/opam:debian-11-ocaml-4.07

RUN sudo apt-get install linux-source libssl-dev libelf-dev wget kmod -y && \
    cp /usr/src/linux-source-5.10.tar.xz /tmp && \
    cd /tmp && \
    tar -xvvJf linux-source-5.10.tar.xz && \
    cd linux-source-5.10 && \
    yes "" | make oldconfig && \
    yes "" | make modules_prepare

COPY adding-fpic-flag.diff /tmp

RUN cd /tmp && \
    git clone https://github.com/luigirizzo/netmap.git && \
    cd netmap && \
    patch -p0 < /tmp/adding-fpic-flag.diff && \
    ./configure --no-drivers --kernel-dir=/tmp/linux-source-5.10 && \
    make && \
    sudo make install


