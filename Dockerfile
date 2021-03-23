FROM ubuntu:20.10

ARG version=dev
ENV version=${version}

RUN apt-get update && \
    apt-get install -y curl jq

ADD /assets/check /opt/resource/
ADD /assets/in /opt/resource/
ADD /assets/out /opt/resource/

RUN chmod +x /opt/resource/*
RUN mkdir -p /opt/resource/common && echo "${version}" > /opt/resource/common/version
