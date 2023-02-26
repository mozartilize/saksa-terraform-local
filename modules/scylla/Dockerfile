FROM debian:11-slim

RUN apt update && \
	apt install -y curl vim systemd systemd-sysv openssh-server gnupg2

RUN systemctl enable ssh

RUN curl -o /etc/apt/sources.list.d/scylla.list http://downloads.scylladb.com/deb/debian/scylla-5.0.list

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys d0a112e067426ab2

RUN apt update && apt install -y scylla

VOLUME ["/sys/fs/cgroup", "/var/log/journal"]

EXPOSE 22 9042 7000

CMD ["/sbin/init"]
