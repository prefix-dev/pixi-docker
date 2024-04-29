# FROM ghcr.io/prefix-dev/pixi:0.18.0 AS build

# COPY . /app
# WORKDIR /app
# RUN pixi run build-wheel
# RUN pixi run postinstall-production
# RUN pixi shell-hook -e prod > /shell-hook
# RUN echo "gunicorn -w 4 docker_project:app --bind :8000" >> /shell-hook

# FROM ubuntu:22.04 AS production

# # only copy the production environment into prod container
# COPY --from=build /app/.pixi/envs/prod /app/.pixi/envs/prod
# COPY --from=build /shell-hook /shell-hook
# WORKDIR /app
# EXPOSE 8000
# CMD ["/bin/bash", "/shell-hook"]


FROM ghcr.io/prefix-dev/pixi:0.18.0 AS build

# copy source code, pixi.toml and pixi.lock to the container
COPY . /app
WORKDIR /app

# run some compilation / build task (if needed)
RUN pixi run build-wheel
RUN pixi run postinstall-production

# Create the shell-hook bash script to activate the environment
RUN pixi shell-hook -e prod > /shell-hook.sh

# extend the shell-hook script to run the command passed to the container
RUN echo 'exec "$@"' >> /shell-hook.sh

FROM ubuntu:22.04 AS production

# only copy the production environment into prod container
# please note that the "prefix" (path) needs to stay the same as in the build container
COPY --from=build /app/.pixi/envs/prod /app/.pixi/envs/prod
COPY --from=build /shell-hook.sh /shell-hook.sh
WORKDIR /app
EXPOSE 8000

# set the entrypoint to the shell-hook script (activate the environment and run the command)
# no more pixi needed in the prod container
ENTRYPOINT ["/bin/bash", "/shell-hook.sh"]

CMD ["gunicorn", "-w", "4", "docker_project:app", "--bind", ":8000"]
