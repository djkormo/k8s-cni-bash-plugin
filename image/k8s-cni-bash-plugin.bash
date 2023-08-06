#!/bin/bash

adddate() {
    while IFS= read -r line; do
        printf '%s %s\n' "$(date)" "$line";
    done
}


log=/var/log/cni.log  #$LOGFILE # TODO , should be based on env 
config=`cat /dev/stdin`
echo "CNI_CONFIG: $config" | adddate >> $log


#set -u
#set -e

echo >> $log
echo "CNI_COMMAND: $CNI_COMMAND" | adddate >> $log
echo "CNI_COMMAND: $CNI_COMMAND" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
echo "CNI_IFNAME: $CNI_IFNAME" | adddate >> $log
echo "CNI_NETNS: $CNI_NETNS" | adddate >> $log
echo "CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> $log

case $CNI_COMMAND in
# Adding network to pod 
ADD
    podcidr=$(echo $config | jq -r ".podcidr")
    podcidr_gw=$(echo $podcidr | sed "s:0/24:1:g")
    echo "Adding IP for Pod CIDR $podcidr" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
    echo "GatewayIP $podcidr_gw" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
    echo "CNI_IFNAME: $CNI_IFNAME" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
    echo "CNI_NETNS: $CNI_NETNS" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
    echo "CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
    echo "CNI_COMMAND: $CNI_COMMAND" | adddate >> $log 
    echo "Adding IP for Pod CIDR $podcidr" | adddate >> $log 
    echo "GatewayIP $podcidr_gw" | adddate >> $log 
    echo "CNI_IFNAME: $CNI_IFNAME" | adddate >> $log 
    echo "CNI_NETNS: $CNI_NETNS" | adddate >> $log 
    echo "CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> $log 

    echo "CNI_COMMAND: $CNI_COMMAND" | adddate 
    echo "Adding IP for Pod CIDR $podcidr" | adddate 
    echo "GatewayIP $podcidr_gw" | adddate 
    echo "CNI_IFNAME: $CNI_IFNAME" | adddate
    echo "CNI_NETNS: $CNI_NETNS" | adddate 
    echo "CNI_CONTAINERID: $CNI_CONTAINERID" | adddate 
    echo "GatewayIP $podcidr_gw" | adddate

    brctl addbr cni0
    ip link set cni0 up
    ip addr add "${podcidr_gw}/24" dev cni0
    
    # calculate $ip
    if [ -f /tmp/last_allocated_ip ]; then
        n=`cat /tmp/last_allocated_ip`
    else
        n=1
    fi
    n=$(($n+1))
    ip=$(echo $podcidr | sed "s:0/24:$n:g")
    echo $n > /tmp/last_allocated_ip

    exit 0

    host_ifname="veth$n"
    ip link add $CNI_IFNAME type veth peer name $host_ifname
    ip link set $host_ifname up

    mkdir -p /var/run/netns/
    ip link set $host_ifname master cni0
    ln -sfT $CNI_NETNS /var/run/netns/$CNI_CONTAINERID
    ip link set $CNI_IFNAME netns $CNI_CONTAINERID

    ip netns exec $CNI_CONTAINERID ip link set $CNI_IFNAME up
    ip netns exec $CNI_CONTAINERID ip addr add $ip/24 dev $CNI_IFNAME
    ip netns exec $CNI_CONTAINERID ip route add default via $podcidr_gw

    mac=$(ip netns exec $CNI_CONTAINERID ip link show eth0 | awk '/ether/ {print $2}')
    address="${ip}/24"
    output_template='
{
  "cniVersion": "0.3.1",
  "interfaces": [                                            
      {
          "name": "%s",
          "mac": "%s",                            
          "sandbox": "%s" 
      }
  ],
  "ips": [
      {
          "version": "4",
          "address": "%s",
          "gateway": "%s",          
          "interface": 0 
      }
  ]
}' 
    
    output=$(printf "${output_template}" $CNI_IFNAME $mac $CNI_NETNS $address $podcidr_gw)
    echo $output >> $log
    echo "$output"
    
;;
# Deleting network from pod 
DEL)
    echo "rm -rf /var/run/netns/$CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> $log
    echo "rm -rf /var/run/netns/$CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
    rm -rf /var/run/netns/$CNI_CONTAINERID
    
;;

GET)

;;

VERSION)
echo '{
  "cniVersion": "0.3.1", 
  "supportedVersions": [ "0.3.0", "0.3.1", "0.4.0" ] 
}'
;;

*)
  echo "Unknown cni command: $CNI_COMMAND" | adddate >> /proc/1/fd/1 2>> /proc/1/fd/2
  echo "Unknown cni command: $CNI_COMMAND" | adddate >> $log
  exit 1
;;

esac
