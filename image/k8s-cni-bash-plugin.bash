#!/bin/bash -e

if [[ ${DEBUG} -gt 0 ]]; then set -x; fi

ip_file=/tmp/last_allocated_ip

# based on

# https://github.com/s-matyukevich/bash-cni-plugin/blob/master/bash-cni
# https://github.com/eranyanay/cni-from-scratch/blob/master/my-cni-demo
# https://github.com/learnk8s/advanced-networking/blob/master/my-cni-plugin


# Direct file descriptors 1 and 2 to log file, and file descriptor 3 to stdout
exec 3>&1
exec &>>/var/log/cni.log

# Write line to log file (file descriptor 1 is redirected to log file)
logger() {
  echo -e "$(date): $*"
}


adddate() {
    while IFS= read -r line; do
        printf '%s %s\n' "$(date)" "$line";
    done
}

allocate_ip(){
	for ip in "${all_ips[@]}"
	do
		reserved=false
		for reserved_ip in "${reserved_ips[@]}"
		do
			if [ "$ip" = "$reserved_ip" ]; then
				reserved=true
				break
			fi
		done
		if [ "$reserved" = false ] ; then
			echo "$ip" >> $IP_STORE
			echo "$ip"
			return
		fi
	done
}

IP_STORE=/tmp/reserved_ips # all reserved ips will be stored there

#exec 3>&1 # make stdout available as fd 3 for the result
log=/var/log/cni.log  #$LOGFILE # TODO , should be based on env 
config=`cat /dev/stdin`

echo "CNI_CONFIG: $config" | adddate >> $log
echo "PATH: ${PATH}" | adddate >> $log

#set -u
#set -e

echo >> $log
echo "CNI_COMMAND: $CNI_COMMAND" | adddate >> $log
echo "CNI_IFNAME: $CNI_IFNAME" | adddate >> $log
echo "CNI_NETNS: $CNI_NETNS" | adddate >> $log
echo "CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> $log
echo "CNI_ARGS: $CNI_ARGS" | adddate >> $log
echo "CNI_PATH: $CNI_PATH" | adddate >> $log
echo "IP temp file: $ip_file" | adddate >> $log

logger "CNI_COMMAND=$CNI_COMMAND, CNI_CONTAINERID=$CNI_CONTAINERID, CNI_NETNS=$CNI_NETNS, CNI_IFNAME=$CNI_IFNAME, CNI_PATH=$CNI_PATH\n$netconf"

case $CNI_COMMAND in
# Adding network to pod 

ADD)
    podcidr=$(echo $config | jq -r ".podcidr")
    podcidr_gw=$(echo $podcidr | sed "s:0/24:1:g")
    subnet_mask_size=$(echo $podcidr | awk -F  "/" '{print $2}')7
    echo "CNI_COMMAND: $CNI_COMMAND" | adddate >> $log 
    echo "Adding IP for Pod CIDR $podcidr" | adddate >> $log 
    echo "GatewayIP $podcidr_gw" | adddate >> $log 
    echo "IP Mask $subnet_mask_size" | adddate >> $log 
    echo "CNI_IFNAME: $CNI_IFNAME" | adddate >> $log 
    echo "CNI_NETNS: $CNI_NETNS" | adddate >> $log 
    echo "CNI_CONTAINERID: $CNI_CONTAINERID" | adddate >> $log 

    # calculate $ip
    if [ -f $ip_file ]; then
        n=`cat $ip_file`
    else
        n=1
        echo "IP number: $n" | adddate >> $log 
    fi
    n=$(($n+1))
    ip=$(echo $podcidr | sed "s:0/24:$n:g")
    echo $n > $ip_file
    echo "IP $ip, number: $n" | adddate >> $log 

    rand=$(tr -dc 'A-F0-9' < /dev/urandom | head -c4)
    host_if_name="veth$rand"
    ip link add $CNI_IFNAME type veth peer name $host_if_name  --ignore-errors
   
    ip link set $host_ifname up  --ignore-errors

    mkdir -p /var/run/netns/
    ip link set $host_ifname master cni0
    ln -sfT $CNI_NETNS /var/run/netns/$CNI_CONTAINERID
    ip link set $CNI_IFNAME netns $CNI_CONTAINERID

    ip netns exec $CNI_CONTAINERID ip link set $CNI_IFNAME up
    ip netns exec $CNI_CONTAINERID ip addr add $ip/24 dev $CNI_IFNAME
    ip netns exec $CNI_CONTAINERID ip route add default via $podcidr_gw

    exit 0	

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

    rm -rf /var/run/netns/$CNI_CONTAINERID
    
;;

CHECK)

;;

VERSION)
echo '{
  "cniVersion": "0.3.1", 
  "supportedVersions": [ "0.3.0", "0.3.1", "0.4.0" ] 
}'
;;

*)

  echo "Unknown CNI_COMMAND: $CNI_COMMAND" | adddate >> $log
  exit 1
;;

esac
