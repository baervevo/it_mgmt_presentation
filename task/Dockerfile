FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        python3 \
        sudo \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd

RUN useradd -m -s /bin/bash deploy \
    && echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy \
    && chmod 0440 /etc/sudoers.d/deploy

COPY target-entry.sh /target-entry.sh
RUN chmod +x /target-entry.sh

EXPOSE 22 80

CMD ["/target-entry.sh"]
