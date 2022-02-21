FROM debian:stable

RUN apt-get update && apt-get upgrade && apt-get install toilet build-essential git curl boxes figlet -y \
    && adduser --gecos "" --disabled-password --home /home/container container

COPY ./breaker /breaker

RUN chmod 0111 /breaker

USER container
ENV  USER=container HOME=/home/container TERM=xterm-256color

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]