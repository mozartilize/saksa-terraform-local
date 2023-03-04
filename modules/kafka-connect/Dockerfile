FROM debian:11-slim

RUN apt update && \
	apt install -y curl vim systemd systemd-sysv openssh-server \
    gnupg2 openjdk-17-jre-headless \
    unzip

RUN systemctl enable ssh

RUN curl https://packages.confluent.io/deb/7.3/archive.key | apt-key add -

RUN echo 'deb [arch=amd64] https://packages.confluent.io/deb/7.3 stable main' > /etc/apt/sources.list.d/confluent-platform.list

RUN apt update && \
    apt install -y confluent-community-2.13

RUN curl -sL https://github.com/scylladb/scylla-cdc-source-connector/releases/download/scylla-cdc-source-connector-1.0.3/scylladb-scylla-cdc-source-connector-1.0.3.zip -o scylladb-scylla-cdc-source-connector-1.0.3.zip

RUN mkdir -p /usr/local/share/kafka/plugins && \
    unzip scylladb-scylla-cdc-source-connector-1.0.3.zip -d /usr/local/share/kafka/plugins && \
    rm scylladb-scylla-cdc-source-connector-1.0.3.zip

VOLUME ["/sys/fs/cgroup", "/var/log/journal"]

EXPOSE 22

CMD ["/sbin/init"]