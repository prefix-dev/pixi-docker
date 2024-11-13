FROM ghcr.io/modular/magic:0.4.0 AS build

# copy source code, pixi.toml and pixi.lock to the container
COPY . /app
WORKDIR /app

# run some compilation / build task (if needed)
RUN magic run build-wheel
RUN magic run postinstall-production

# Create the shell-hook bash script to activate the environment
RUN magic shell-hook -e prod > /shell-hook.sh

# extend the shell-hook script to run the command passed to the container
RUN echo 'exec "$@"' >> /shell-hook.sh

FROM ubuntu:22.04 AS production

# only copy the production environment into prod container
# please note that the "prefix" (path) needs to stay the same as in the build container
COPY --from=build /app/.magic/envs/prod /app/.magic/envs/prod
COPY --from=build /shell-hook.sh /shell-hook.sh
WORKDIR /app
EXPOSE 8000

# set the entrypoint to the shell-hook script (activate the environment and run the command)
# no more magic needed in the prod container
ENTRYPOINT ["/bin/bash", "/shell-hook.sh"]

CMD ["gunicorn", "-w", "4", "docker_project:app", "--bind", ":8000"]
