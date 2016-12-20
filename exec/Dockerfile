FROM ubuntu:xenial
MAINTAINER duzy <code@duzy.info>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -q -y --allow-unauthenticated \
    apt-utils iputils-ping iputils-tracepath ntp ntpdate

RUN apt-get install -q -y --allow-unauthenticated \
    libboost-date-time1.58.0 \
    libboost-system1.58.0 \
    libboost-thread1.58.0 \
    libboost-iostreams1.58.0 \
    libboost-chrono1.58.0 \
    libboost-filesystem1.58.0 \
    libboost-program-options1.58.0

RUN apt-get install -q -y --allow-unauthenticated \
    libdb5.3++ \
    libminiupnpc10 \
    libevent-pthreads-2.0-5 \
    libevent-2.0-5

RUN apt-get install -q -y --allow-unauthenticated \
    daemontools

RUN useradd -m -s /bin/bash -p /task duzy

COPY entrypoint /bin/entrypoint
RUN chmod 0755 /bin/entrypoint

VOLUME /task

EXPOSE 9333/tcp
EXPOSE 19333/tcp

USER root:root
ENTRYPOINT ["/bin/entrypoint"]
