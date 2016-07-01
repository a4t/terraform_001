FROM alpine:3.3

MAINTAINER Shigure Onishi <iwanomoto@gmail.com>

ENV TERRAFORM_VERSION=0.7.0-rc2

RUN apk update && \
    apk add bash \
    ca-certificates \
    git \
    openssl \
    zip \
    unzip \
    wget \
    python \
    py-pip \
    py-setuptools \
    ca-certificates \
    groff \
    less && \
    pip install awscli && \
    wget -P /tmp https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

ADD ./scripts /scripts

ENTRYPOINT ["/scripts/terraform.sh"]

CMD ["--help"]
