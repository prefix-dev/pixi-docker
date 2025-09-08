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

- `latest` - based on `ubuntu:noble`
- `focal` - based on `ubuntu:focal`
- `bullseye` - based on `debian:bullseye`
- `noble-cuda-12.9.1` - based on `nvidia/cuda:12.9.1-base-ubuntu24.04`
- `noble-cuda-13.0.0` - based on `nvidia/cuda:13.0.0-base-ubuntu24.04`
- ... and more

## Usage with shell-hook

The following example uses the pixi docker image as a base image for a multi-stage build.
It also makes use of the `shell-hook` feature of pixi to define a convenient entry point (after executing the `shell-hook` script, the environment is activated.

```Dockerfile
FROM ghcr.io/prefix-dev/pixi:0.40.0 AS build

# copy source code, pixi.toml and pixi.lock to the container
COPY . /app
WORKDIR /app
# run some compilation / build task (if needed)
RUN pixi run build
# run the `install` command (or any other). This will also install the dependencies into `/app/.pixi`
# assumes that you have a `prod` environment defined in your pixi.toml
RUN pixi install -e prod
# Create the shell-hook bash script to activate the environment
RUN pixi shell-hook -e prod > /shell-hook.sh

# extend the shell-hook script to run the command passed to the container
RUN echo 'exec "$@"' >> /shell-hook.sh

FROM ubuntu:24.04 AS production

# only copy the production environment into prod container
# please note that the "prefix" (path) needs to stay the same as in the build container
COPY --from=build /app/.pixi/envs/prod /app/.pixi/envs/prod
COPY --from=build /shell-hook.sh /shell-hook.sh
WORKDIR /app
EXPOSE 8000

# set the entrypoint to the shell-hook script (activate the environment and run the command)
# no more pixi needed in the prod container
ENTRYPOINT ["/bin/bash", "/shell-hook.sh"]

CMD ["start-server"]
```

## Images

There are images based on `ubuntu`, `debian` and `nvidia/cuda` available.

### Ubuntu

The [`ubuntu:noble`](https://hub.docker.com/_/ubuntu) (24.04) based image is the default base image. It is used for the `latest` and `0.x.y` tag.

There are also images based on `ubuntu:focal` (20.04), `ubuntu:jammy` (22.04), `ubuntu:oracular` (24.10) and `ubuntu:plucky` (25.04) available.
These images use the tags `focal`, `0.x.y-focal`, ...

### Debian

Images based on [`debian:bullseye`](https://hub.docker.com/_/debian), `debian:bullseye-slim` (11), `debian:bookworm` and `debian:bookworm-slim` (12) are available.

These images have the tags `bullseye`, `0.x.y-bullseye`, ...

### NVIDIA/CUDA

Images based on [`nvidia/cuda`](https://hub.docker.com/r/nvidia/cuda) are available using the tags `cuda-<cuda-version>-jammy`, `cuda-<cuda-version>-focal`, `0.x.y-cuda-<cuda-version>-jammy`, ...
