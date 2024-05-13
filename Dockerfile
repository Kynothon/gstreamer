ARG DEBIAN_VERSION=trixie-slim

FROM debian:${DEBIAN_VERSION} as builder

WORKDIR /usr/src

RUN apt-get update \
    && apt-get install -yqq \
    gcc \
    g++ \
    libc6-dev \
    make \
    git \
    meson \
    flex \
    bison \
    libssl-dev \
    nasm \
    pkg-config \
    libudev-dev \
    gitlint \
    curl \
    libpython3.11-dev \
    libglib2.0-dev \
    libgudev-1.0-dev \
    libzstd-dev \
    libdrm-dev


ENV CARGO_HOME=/usr
ENV RUSTUP_HOME=/usr

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && cargo install cargo-c


FROM builder as build

ARG GST_VERSION=1.24.3

RUN git clone --depth 1 --branch ${GST_VERSION} https://gitlab.freedesktop.org/gstreamer/gstreamer.git \
    && cd gstreamer \
    && meson setup build-gst-full \     
    --reconfigure \
    --strip \
    --prefix /opt/gstreamer \
    -Dbuildtype=release \
    -Dpython=disabled \
    -Drs=enabled  \
    -Dgpl=enabled \
    -Dbad=enabled \ 
    -Dugly=enabled \
    -Dlibav=enabled \
    -Ddevtools=disabled \
    -Ddoc=disabled \
    -Dexamples=disabled \
    -Dtests=disabled \
    -Dintrospection=enabled \
    -Dgst-plugins-bad:openh264=enabled \
    -Dgst-plugins-ugly:x264=enabled \
    -Dgst-plugins-rs:gtk4=disabled \
    -Dgst-plugins-bad:va=disabled

RUN cd gstreamer \
    && meson compile -C build-gst-full \
    && meson install -C build-gst-full

FROM debian:${DEBIAN_VERSION} as release

cp --from=build /opt/gstreamer /opt/gstreamer
