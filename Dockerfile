ARG PIXI_VERSION=0.46.0
ARG BASE_IMAGE=debian:bookworm-slim

FROM --platform=$TARGETPLATFORM ubuntu:24.04 AS builder
# need to specify the ARG again to make it available in this stage
ARG PIXI_VERSION
RUN apt-get update && apt-get install -y curl
# download the musl build since the gnu build is not available on aarch64
RUN curl -Ls \
    "https://github.com/prefix-dev/pixi/releases/download/v${PIXI_VERSION}/pixi-$(uname -m)-unknown-linux-musl" \
    -o /pixi && chmod +x /pixi
RUN /pixi --version

FROM --platform=$TARGETPLATFORM $BASE_IMAGE
COPY --from=builder --chown=root:root --chmod=0555 /pixi /usr/local/bin/pixi
ENV PATH="/root/.pixi/bin:${PATH}"
