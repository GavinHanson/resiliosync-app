FROM ubuntu:18.04

MAINTAINER Cylo <noc@cylo.io>

ENV RSLSYNC_SIZE=10000 \
    RSLSYNC_TRASH_TIME=7 \
    RSLSYNC_TRASH=false \
    INSTANCE_ID=0 \
    HOME=/home/appbox

RUN adduser --system --disabled-password --home ${HOME} --shell /sbin/nologin --group --uid 1000 appbox

RUN apt update && apt install -y zip curl bash wget libcap2-bin

VOLUME /home/appbox/storage

ADD /scripts /scripts
RUN chmod -R +x /scripts

ENTRYPOINT [ "/scripts/Entrypoint.sh" ]

EXPOSE 33333
EXPOSE 80
