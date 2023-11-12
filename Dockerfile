FROM debian:bullseye as builder
WORKDIR /tmp
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    cmake \
    git \
    curl \
    unzip \
    xz-utils \
    build-essential \
    ninja-build \
    pkg-config \
    zlib1g \
    zlib1g-dev \
    liblzma5 \
    liblzma-dev \
    liblzo2-2 \
    liblzo2-dev \
    libzstd-dev \
    libpng16-16 \
    libpng-dev
ENV openttd_repo=https://github.com/Lee0701/OpenTTD.git
ENV openttd_branch=13.4
ENV opengfx_version=7.1
RUN git clone --branch $openttd_branch $openttd_repo
RUN curl -fLo opengfx-$opengfx_version-all.zip https://cdn.openttd.org/opengfx-releases/$opengfx_version/opengfx-$opengfx_version-all.zip
RUN mkdir /tmp/build

WORKDIR /tmp/build
RUN cmake \
    -B build \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CMAKE_INSTALL_BINDIR=bin \
    -D CMAKE_INSTALL_DATADIR=/usr/share \
    -D OPTION_DEDICATED=ON \
    -D DEFAULT_PERSONAL_DIR=/data \
    -G Ninja \
    -S /tmp/OpenTTD
RUN ninja -C build
RUN ninja -C build install

WORKDIR /tmp
RUN unzip opengfx-$opengfx_version-all.zip
RUN mv opengfx-$opengfx_version.tar /usr/share/openttd/baseset/opengfx-$opengfx_version.tar

FROM debian:bullseye
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
           zlib1g \
           liblzma5 \
           liblzo2-2 \
           libzstd1 \
           libpng16-16 \
    && apt-get clean \
    && rm -rvf /var/lib/apt/lists/* /var/log/apt /var/log/dpkg.log
COPY --from=builder /usr/bin/openttd /usr/bin/openttd
COPY --from=builder /usr/share/openttd/ /usr/share/openttd/
COPY --from=builder /usr/share/doc/openttd/ /usr/share/doc/openttd/
COPY --from=builder /usr/share/man/man6/openttd.6.gz /usr/share/man/man6/openttd.6.gz
RUN useradd -ms /bin/sh -d /data openttd
USER openttd:openttd
EXPOSE 3979
EXPOSE 3979/udp
WORKDIR /data
ENV XDG_DATA_HOME=/data
VOLUME ["/data"]
ENTRYPOINT ["/usr/bin/openttd"]
