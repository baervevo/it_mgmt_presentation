#!/usr/bin/env bash
set -e

if [ ! -f /keys/id ]; then
    ssh-keygen -t ed25519 -N "" -C "lab" -f /keys/id >/dev/null
fi
cp /keys/id.pub /keys/authorized_keys
chmod 600 /keys/id
chmod 644 /keys/id.pub /keys/authorized_keys

if [ ! -e /root/workspace/.git ]; then
    git clone -q /opt/lab-repo.bundle /root/workspace
    git -C /root/workspace remote remove origin 2>/dev/null || true
    chmod -R a+rwX /root/workspace
fi

echo ">> [control] Środowisko gotowe, wykonaj:"
echo ">>   docker compose exec control bash"
exec sleep infinity
