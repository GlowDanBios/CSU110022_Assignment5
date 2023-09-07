FROM mcr.microsoft.com/vscode/devcontainers/base:alpine-3.18

RUN apk add --no-cache \
    make \
    g++-arm-none-eabi \
    qemu-system-arm \
    gdb-multiarch \
    openocd

COPY --chown=vscode:vscode settings.json /home/vscode/.vscode-server/data/Machine/settings.json
