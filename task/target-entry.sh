#!/bin/bash
set -e

while [ ! -f /keys/authorized_keys ]; do
    sleep 1
done

install -d -o deploy -g deploy -m 700 /home/deploy/.ssh
install -o deploy -g deploy -m 600 /keys/authorized_keys /home/deploy/.ssh/authorized_keys

mkdir -p /run/sshd
exec /usr/sbin/sshd -D -e
