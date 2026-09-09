# pixi-docker

This repository contains the docker configuration for the pixi container image.
The pixi container image is based on different base images, depending on the use case.
The Ubuntu, Debian and CUDA images have pixi installed in `/usr/local/bin/pixi`.
The separate `pixi-runtime` image contains only the system libraries and Bash needed to run a copied environment.

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

The runtime-only image is published as a separate package,
[`ghcr.io/prefix-dev/pixi-runtime`](https://github.com/prefix-dev/pixi-docker/pkgs/container/pixi-runtime),
because it does not contain pixi:

```bash
docker pull ghcr.io/prefix-dev/pixi-runtime:glibc-bash
```

## Usage with shell-hook

The following example uses the pixi docker image as a base image for a multi-stage build.
The `shell-hook` entrypoint activates the environment before executing the container command.

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

FROM ghcr.io/prefix-dev/pixi-runtime:glibc-bash AS production

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

Copy any application files and activation scripts referenced by the shell hook as well.
The runtime image does not contain system utilities; see its requirements below.

## Images

There are images based on `ubuntu`, `debian` and `nvidia/cuda` available.

### Minimal runtime

`ghcr.io/prefix-dev/pixi-runtime:glibc-bash` is built from [`Dockerfile.runtime`](Dockerfile.runtime)
for `linux/amd64` and `linux/arm64`. It contains glibc and its loader, UTF-8 locale
data, Bash, `libtinfo`, and user/group and name-service configuration.
It supports running as UID/GID `65532:65532`.

This image is for the final stage of a multi-stage build, not for installing environments.
It contains no Pixi, package manager, coreutils, `/bin/sh`, or system CA bundle.
Bash is included for non-interactive shell hooks; terminal descriptions (terminfo)
are not included. Add terminal data to the environment if the application needs it.
Include the application's other dependencies, including `ca-certificates` for HTTPS,
in the Pixi environment. Some clients need `SSL_CERT_FILE` pointed at the environment's
`ssl/cacert.pem`. Use an Ubuntu or Debian base when the application or its activation
scripts require system utilities or `/bin/sh`.
The environment must also provide a discoverable `libgcc_s` when the application
uses glibc thread cancellation or `pthread_exit`; the base image does not include it.

Runtime images are published on changes to the runtime build, separately from Pixi
releases. The tags are `glibc-bash` and `glibc-bash-<full-git-commit>`, naming the
runtime components the image provides. Pin an image digest for deployments.

To build the runtime and example locally:

```bash
docker build -f Dockerfile.runtime -t pixi-runtime:local .
docker build --build-arg RUNTIME_IMAGE=pixi-runtime:local -t pixi-example example
docker run --rm -p 8000:8000 pixi-example
```

#### SBOM provenance

The image retains metadata in `/usr/share/pixi-runtime/`:

- `sbom/` contains the upstream SPDX package SBOMs for the extracted components.
- `origins.tsv` maps each extracted file to its source path and package version.
- `files.sha256` records the extracted files' SHA-256 checksums.

These are source-package SBOMs, not a claim that the complete APK packages are
installed. The APK database is not copied. Generate a final-image SBOM that also
includes the conda environment and application when building your application image.

### Ubuntu

The [`ubuntu:noble`](https://hub.docker.com/_/ubuntu) (24.04) based image is the default base image. It is used for the `latest` and `0.x.y` tag.

There are also images based on `ubuntu:focal` (20.04), `ubuntu:jammy` (22.04), `ubuntu:oracular` (24.10) and `ubuntu:plucky` (25.04) available.
These images use the tags `focal`, `0.x.y-focal`, ...

### Debian

Images based on [`debian:bullseye`](https://hub.docker.com/_/debian), `debian:bullseye-slim` (11), `debian:bookworm`, `debian:bookworm-slim` (12), `debian:trixie` and `debian:trixie-slim` (13) are available.

These images have the tags `bullseye`, `0.x.y-bullseye`, ...

### NVIDIA/CUDA

Images based on [`nvidia/cuda`](https://hub.docker.com/r/nvidia/cuda) are available using the tags `cuda-<cuda-version>-jammy`, `cuda-<cuda-version>-focal`, `0.x.y-cuda-<cuda-version>-jammy`, ...
