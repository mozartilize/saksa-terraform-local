FROM python:3.10-slim-bullseye

RUN apt update && \
	apt install -y curl vim systemd systemd-sysv openssh-server librdkafka1

RUN systemctl enable ssh

RUN curl -L https://github.com/mozartilize/saksa/releases/download/0.2.dev28/saksa-0.2.0.dev28-py3-none-any.whl \
	-o saksa-0.2.0.dev28-py3-none-any.whl

RUN pip install saksa-0.2.0.dev28-py3-none-any.whl

VOLUME ["/sys/fs/cgroup", "/var/log/journal"]

EXPOSE 22 8000

CMD ["/sbin/init"]
