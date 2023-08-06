FROM alpine:3.18.2
LABEL maintainer="Krzysztof Pudlowski <djkormo@gmail.com>" version="1.0.0"

RUN apk --no-cache add  gcc musl-dev curl bash

COPY k8s-api-check.bash k8s-api-check.bash
COPY 10-k8s-cni-bash-plugin.conf 10-k8s-cni-bash-plugin.conf
COPY k8s-cni-bash-plugin.bash k8s-cni-bash-plugin.bash
COPY start.sh start.sh



