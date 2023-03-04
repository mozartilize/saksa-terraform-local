FROM python:3.10-slim-bullseye

RUN apt update && \
	apt install -y curl vim systemd systemd-sysv openssh-server librdkafka1

VOLUME ["/sys/fs/cgroup", "/var/log/journal"]

EXPOSE 22 8000

CMD ["/sbin/init"]
