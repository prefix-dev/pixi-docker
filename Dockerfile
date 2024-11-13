ARG MAGIC_VERSION=0.4.0
ARG BASE_IMAGE=debian:bookworm-slim

FROM --platform=$TARGETPLATFORM ubuntu:24.04 AS builder
# need to specify the ARG again to make it available in this stage
ARG MAGIC_VERSION
RUN apt-get update && apt-get install -y curl
# download the musl build since the gnu build is not available on aarch64
RUN curl -Ls \
    "https://dl.modular.com/public/magic/raw/versions/${MAGIC_VERSION}/magic-$(uname -m)-unknown-linux-musl" \
    -o /magic && chmod +x /magic
RUN /magic --version

FROM --platform=$TARGETPLATFORM $BASE_IMAGE
COPY --from=builder --chown=root:root --chmod=0555 /magic /usr/local/bin/magic
