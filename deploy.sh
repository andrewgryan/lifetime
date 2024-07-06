#!/bin/bash
set -x

# Sync static assets
rsync -vrz public/ zero:~/lifetime/public

# Stop service, replace executable, start service
ssh zero "sudo systemctl stop lifetime.service"
scp zig-out/bin/lifetime zero:~/lifetime/
ssh zero "sudo systemctl start lifetime.service"
