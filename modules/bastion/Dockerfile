FROM debian:11-slim

RUN apt update && \
	apt install -y curl vim systemd systemd-sysv openssh-server

RUN systemctl enable ssh

VOLUME ["/sys/fs/cgroup", "/var/log/journal"]

EXPOSE 22

CMD ["/sbin/init"]
