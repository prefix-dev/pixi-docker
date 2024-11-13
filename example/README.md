# Docker example

This example is using docker in combination with [solve-groups](https://pixi.sh/latest/configuration/#the-environments-table).
The solve-groups ensure that the `default` environment (where the tests are run) is using *exactly* the same versions of the dependencies as the `prod` environment.

In the docker container, we only copy the `prod` environment into the final layer, so the `default` environment and all its dependencies are not included in the final image.
Also, `magic` itself is not included in the final image and we activate the environment using `magic -e prod shell-hook`.

## Usage

To build and run the docker container you require [`docker`](https://docs.docker.com/engine/install/)
When you have `docker` use the following commands:

```shell
docker build -t magic-docker .
docker run -p 8000:8000 magic-docker
```
