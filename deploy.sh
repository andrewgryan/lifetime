#!/bin/bash
set -x

# Build executable
zig build -Dtarget=aarch64-linux

# Sync static assets
rsync -vrz public/ zero:~/lifetime/public

# Stop service, replace executable, start service
ssh zero "sudo systemctl stop lifetime.service"
scp zig-out/bin/lifetime zero:~/lifetime/
ssh zero "sudo systemctl start lifetime.service"
