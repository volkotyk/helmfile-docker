FROM hashicorp/terraform:1.1.4 AS terraform

FROM debian:bullseye-slim

ARG KUBECTL_VERSION=1.20.15
ARG HELM_VERSION=3.7.2
ARG HELM_DIFF_VERSION=3.4.1
ARG HELM_SECRETS_VERSION=3.11.0
ARG HELMFILE_VERSION=0.143.0
ARG HELM_S3_VERSION=0.10.0
ARG HELM_GIT_VERSION=0.11.1
ARG AWS_CLI_VERSION=2.4.1
ARG JX_RELEASE_VERSION_V=2.5.1
ARG YQ_VERSION=4.17.2

WORKDIR /

RUN apt update && apt install -y git gnupg curl gettext jq unzip sudo python3-pip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf aws awscliv2.zip \
  && rm -rf ./aws \
  && rm -rf /var/lib/apt/lists
RUN aws --version
RUN pip3 install ec2instanceconnectcli
RUN mssh -h
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl
RUN kubectl version --client

ADD https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
RUN chmod +x /usr/local/bin/aws-iam-authenticator
RUN aws-iam-authenticator version

ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /tmp
RUN tar -zxvf /tmp/helm* -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && rm -rf /tmp/*
RUN helm version

ADD https://github.com/jenkins-x-plugins/jx-release-version/releases/download/v${JX_RELEASE_VERSION_V}/jx-release-version-linux-amd64.tar.gz /tmp
RUN tar -zxvf /tmp/jx-release* -C /tmp \
  && mv /tmp/jx-release-version /usr/local/bin
RUN jx-release-version -version

RUN helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
    helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
    helm plugin install https://github.com/hypnoglow/helm-s3 --version ${HELM_S3_VERSION} && \
    helm plugin install https://github.com/aslafy-z/helm-git --version ${HELM_GIT_VERSION}

ADD https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 /bin/helmfile
RUN chmod 0755 /bin/helmfile
RUN helmfile version

RUN curl -LO https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64  \
  && mv ./yq_linux_amd64 /usr/bin/yq  \
  && chmod +x /usr/bin/yq
RUN yq -V

COPY --from=terraform /bin/terraform /bin/terraform
RUN terraform version

ENTRYPOINT ["/bin/bash"]
