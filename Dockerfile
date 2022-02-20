FROM debian:latest

COPY ./breaker /breaker

RUN apt update && apt upgrade && apt install toilet build-essential git curl boxes figlet -y \
    && adduser --gecos "" --disabled-password --home /home/container container && chmod 0110 /breaker

USER container
ENV  USER=container HOME=/home/container TERM=xterm-256color

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]