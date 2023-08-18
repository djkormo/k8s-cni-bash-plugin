FROM alpine:3.18.2
LABEL maintainer="Krzysztof Pudlowski <djkormo@gmail.com>" version="0.0.1"

RUN apk --no-cache add curl bash jq nmap iptables util-linux

RUN mkdir -p /cni
WORKDIR /cni

COPY k8s-api-check.bash k8s-api-check.bash
#COPY 10-k8s-cni-bash-plugin.conf 10-k8s-cni-bash-plugin.conf
COPY k8s-cni-bash-plugin.bash k8s-cni-bash-plugin.bash
COPY start.sh start.sh
COPY stop.sh stop.sh
COPY cni-add-check.bash cni-add-check.bash 
COPY cni-del-check.bash cni-del-check.bash 
COPY iptables-setup.bash iptables-setup.bash 
COPY k8s-cni-bash-plugin.env k8s-cni-bash-plugin.env 
#COPY export $(cat .env)
RUN chmod +x /cni/*.bash
RUN chmod +x /cni/*.sh

