FROM ubuntu:20.10

RUN apt-get update && \
    apt-get install -y curl jq

ADD /assets/* /opt/resource/

RUN chmod +x /opt/resource/*
