## -*- dockerfile-image-name: "alacritty-builder" -*-
ARG BASE_IMAGE="ubuntu:jammy"
FROM ${BASE_IMAGE} AS builder

ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get install -y \
    cargo \
    cmake \
    git \
    libfreetype6-dev \
    libfontconfig1-dev \
    libxcb-xfixes0-dev \
    libxkbcommon-dev  \
    pkg-config \
    python3 \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/

# Packages for building man pages
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get install -y \
    gzip \
    scdoc \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/

RUN mkdir --verbose --parents /usr/src/alacritty/
WORKDIR /usr/src/alacritty/

ARG GIT_BRANCH
RUN git clone --depth 1 --branch ${GIT_BRANCH:-master} https://github.com/alacritty/alacritty .

# Build Alacritty binary
RUN cargo build --release

# Build terminfo files
RUN tic -xe alacritty,alacritty-direct extra/alacritty.info

# Build man pages
RUN \
  scdoc < extra/man/alacritty.1.scd | gzip -c > target/release/alacritty.1.gz && \
  scdoc < extra/man/alacritty-msg.1.scd | gzip -c > target/release/alacritty-msg.1.gz \
  scdoc < extra/man/alacritty.5.scd | gzip -c > target/release/alacritty.5.gz \
  scdoc < extra/man/alacritty-bindings.5.scd | gzip -c > target/release/alacritty-bindings.5.gz

FROM scratch AS export-stage

COPY --from=builder /usr/src/alacritty/target/release/alacritty .
COPY --from=builder /etc/terminfo/a/alacritty .terminfo/
COPY --from=builder /etc/terminfo/a/alacritty-direct .terminfo/
COPY --from=builder /usr/src/alacritty/target/release/alacritty.1.gz ./man/man1/
COPY --from=builder /usr/src/alacritty/target/release/alacritty-msg.1.gz ./man/man1/
COPY --from=builder /usr/src/alacritty/target/release/alacritty.5.gz ./man/man5/
COPY --from=builder /usr/src/alacritty/target/release/alacritty-bindings.5.gz ./man/man5/
