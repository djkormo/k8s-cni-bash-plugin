FROM alpine:3.18.3
LABEL maintainer="Krzysztof Pudlowski <djkormo@gmail.com>" version="0.0.1"

RUN apk --no-cache add curl bash jq nmap iptables util-linux xxd

RUN mkdir -p /cni
WORKDIR /cni

COPY k8s-api-check.sh k8s-api-check.sh
COPY k8s-cni-bash-plugin.sh k8s-cni-bash-plugin.sh
COPY start.sh start.sh
COPY stop.sh stop.sh
COPY cni-add-check.sh cni-add-check.sh 
COPY cni-del-check.sh cni-del-check.sh 
COPY iptables-setup.sh iptables-setup.sh 
COPY generate-configuration.sh generate-configuration.sh
COPY k8s-cni-bash-plugin.env k8s-cni-bash-plugin.env 

RUN chmod +x /cni/*.sh



