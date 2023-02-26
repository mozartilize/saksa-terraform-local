FROM python:3.10-slim-bullseye

RUN apt update && \
	apt install -y curl vim systemd systemd-sysv openssh-server

RUN systemctl enable ssh

RUN curl -1sLf 'https://dl.redpanda.com/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh' | \
	bash && apt install redpanda -y

VOLUME ["/sys/fs/cgroup", "/var/log/journal"]

EXPOSE 22 8000

CMD ["/sbin/init"]
