ARG PIXI_VERSION=0.72.1
ARG BASE_IMAGE=debian:bookworm-slim

FROM --platform=$TARGETPLATFORM ubuntu:resolute-20260610@sha256:53958ec7b67c2c9355df922dd08dbf0360611f8c3cdb656875e81873db9ffdba AS builder
# need to specify the ARG again to make it available in this stage
ARG PIXI_VERSION
RUN apt-get update && apt-get install -y curl
# download the musl build since the gnu build is not available on aarch64
RUN curl -Ls \
    "https://github.com/prefix-dev/pixi/releases/download/v${PIXI_VERSION}/pixi-$(uname -m)-unknown-linux-musl" \
    -o /pixi && chmod +x /pixi
RUN /pixi --version

FROM --platform=$TARGETPLATFORM $BASE_IMAGE
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder --chown=root:root --chmod=0555 /pixi /usr/local/bin/pixi
RUN printf '\neval "$(pixi completion --shell bash)"\n' >> /root/.bashrc
ENV PATH="/root/.pixi/bin:${PATH}"
