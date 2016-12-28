FROM ubuntu:xenial
MAINTAINER duzy <code@duzy.info>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -q -y --allow-unauthenticated \
    apt-utils bsdmainutils iputils-ping iputils-tracepath ntp ntpdate \
    git pkg-config autotools-dev automake autoconf libtool

RUN apt-get install -q -y --allow-unauthenticated \
    libboost-date-time1.58-dev \
    libboost-system1.58-dev \
    libboost-thread1.58-dev \
    libboost-iostreams1.58-dev \
    libboost-chrono1.58-dev \
    libboost-filesystem1.58-dev \
    libboost-program-options1.58-dev \
    libboost-test1.58-dev

RUN apt-get install -q -y --allow-unauthenticated \
    libdb5.3++-dev \
    libminiupnpc-dev \
    libevent-dev \
    libssl-dev

RUN apt-get install -q -y --allow-unauthenticated \
    gcc-5 g++-5 gdb

RUN apt-get install -q -y --allow-unauthenticated \
    emacs24-nox

RUN useradd -m -s /bin/bash -p /task duzy

COPY entrypoint /bin/entrypoint
RUN chmod 0755 /bin/entrypoint
RUN cd /usr/bin &&\
    ln -sf gcc-5 gcc && \
    ln -sf gcc-ar-5 gcc-ar && \
    ln -sf gcc-nm-5 gcc-nm && \
    ln -sf gcc-ranlib-5 gcc-ranlib && \
    ln -sf g++-5 g++ && \
    ln -sf gcov-tools-5 gcov-tools && \
    ln -sf gcov-5 gcov && \
    true

COPY entrypoint /bin/entrypoint
RUN chmod 0755 /bin/entrypoint
RUN chmod 0777 /tmp

VOLUME /task

EXPOSE 8181/tcp 18181/tcp 8125/tcp 18125/tcp

USER root:root
ENTRYPOINT ["/bin/entrypoint"]
