# pixi-docker

This repository contains the docker configuration for the pixi container image.
The pixi container image is based on different base images, depending on the use case.
All images have pixi installed in `/usr/local/bin/pixi` and are ready to use.

## Pulling the images

The images are [available on "GHCR" (Github Container Registry)](https://github.com/prefix-dev/pixi-docker/pkgs/container/pixi).
You can pull them using docker like so:

```bash
docker pull ghcr.io/prefix-dev/pixi:latest
```

There are different tags for different base images available:

- `latest` - based on `ubuntu:jammy`
- `focal` - based on `ubuntu:focal`
- `bullseye` - based on `debian:bullseye`
- `jammy-cuda-12.2.2` - based on `nvidia/cuda:12.2.2-jammy`
- ... and more

## Images

There are images based on `ubuntu`, `debian` and `nvidia/cuda` available.

### Ubuntu

The `ubuntu:jammy` (22.04) based image is the default base image. It is used for the `latest` and `0.x.y` tag.

There are also images based on `ubuntu:focal` (20.04), `ubuntu:mantic` (23.10) and `ubuntu:noble` (24.04) available.
These images use the tags `focal`, `0.x.y-focal`, ...

### Debian

Images based on `debian:bullseye`, `debian:bullseye-slim` (11), `debian:bookworm` and `debian:bookworm-slim` (12) are available.

These images have the tags `bullseye`, `0.x.y-bullseye`, ...

### NVIDIA/CUDA

Images based on `nvidia/cuda` are available using the tags `cuda-<cuda-version>-jammy`, `cuda-<cuda-version>-focal`, `0.x.y-cuda-<cuda-version>-jammy`, ...
