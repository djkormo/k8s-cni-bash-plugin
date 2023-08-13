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
log=/var/log/cni.log #$CNI_LOGFILE # TODO , should be based on env 
cniconf=`cat /dev/stdin`

logger "CNI_CONFIG: $cniconf" 
logger "PATH: ${PATH}"
logger "CNI_LOGFILE: ${CNI_LOGFILE}"

#set -u
#set -e

logger "CNI_COMMAND: $CNI_COMMAND" 
logger "CNI_IFNAME: $CNI_IFNAME" 
logger "CNI_NETNS: $CNI_NETNS" 
logger "CNI_CONTAINERID: $CNI_CONTAINERID" 
logger "CNI_ARGS: $CNI_ARGS" 
logger "CNI_PATH: $CNI_PATH" 
logger "IP temp file: $ip_file"

logger "CNI_COMMAND=$CNI_COMMAND, CNI_CONTAINERID=$CNI_CONTAINERID, CNI_NETNS=$CNI_NETNS, CNI_IFNAME=$CNI_IFNAME, CNI_PATH=$CNI_PATH\n$netconf"

case $CNI_COMMAND in
# Adding network to pod 

ADD)
    host_network=$(echo $cniconf | jq -r ".network")
    podcidr=$(echo $cniconf | jq -r ".podcidr")
    podcidr_gw=$(echo $podcidr | sed "s:0/24:1:g")
    subnet_mask_size=$(echo $podcidr | awk -F  "/" '{print $2}')
    
    # Prepare NetConf for host-local IPAM plugin (add 'ipam' field)
    ipam_netconf=$(jq ". += {ipam:{subnet:\"$podcidr\", gateway:\"$podcidr_gw\"}}" <<<"$cniconf")
    logger "ipam_netconf: $ipam_netconf"
    ipam_response=$(/opt/cni/bin/host-local <<<"$ipam_netconf")
    logger "ipam_response: $ipam_response"
    # Extract IP addresses for Pod and gateway (bridge) from IPAM response
    ipam_pod_ip=$(jq -r '.ips[0].address' <<<"$ipam_response")
    ipam_bridge_ip=$(jq -r '.ips[0].gateway' <<<"$ipam_response")
    ipam_code=$(jq -r '.code' <<<"$ipam_response")
    ipam_msg=$(jq -r '.msg' <<<"$ipam_response")


 # The lock provides mutual exclusivity (at most one process in the critical
    # section) and synchronisation (no process reaches the Pod-specific setup
    # before the one-time setup has been fully completed at least once).
    {
      # Acquire lock, or wait if it is already taken
      flock 100

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      # Begin of critical section
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

      # Create bridge only if it doesn't yet exist
      if ! ip link show cni0 &>/dev/null; then
        ip link add cni0 type bridge
        ip address add "$ipam_bridge_ip/24" dev cni0
        ip link set cni0 up
      fi
    
      # Create an iptables rule only if it doesn't yet exist
      ensure() {
        eval "$(sed 's/-A/-C/' <<<"$@")" &>/dev/null || eval "$@"
      }

      # Allow forwarding of packets in default network namespace to/from Pods
      ensure iptables -A FORWARD -s "$podcidr" -j ACCEPT
      ensure iptables -A FORWARD -d "$podcidr" -j ACCEPT

      # Set up NAT for traffic leaving the cluster (replace Pod IP with node IP)
      iptables -t nat -N MY_CNI_MASQUERADE &>/dev/null
      ensure iptables -t nat -A MY_CNI_MASQUERADE -d "$podcidr" -j RETURN
      ensure iptables -t nat -A MY_CNI_MASQUERADE -d "$host_network" -j RETURN
      ensure iptables -t nat -A MY_CNI_MASQUERADE -j MASQUERADE
      ensure iptables -t nat -A POSTROUTING -s "$podcidr" -j MY_CNI_MASQUERADE

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      # End of critical section
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    } 100>/tmp/k8s-cni-bash-plugin.lock
    
    logger "CNI_COMMAND: $CNI_COMMAND"
    logger "Adding IP for Pod CIDR $podcidr"  
    logger "GatewayIP $podcidr_gw" 
    logger "IP Mask $subnet_mask_size" 
    logger "CNI_IFNAME: $CNI_IFNAME" 
    logger "CNI_NETNS: $CNI_NETNS"  
    logger "CNI_CONTAINERID: $CNI_CONTAINERID" 
    logger "IPAM pod_ip: $ipam_pod_ip" 
    logger "IPAM bridge_ip: $ipam_bridge_ip" 
    logger "IPAM code: $ipam_code" 
    logger "IPAM msg: $ipam_msg" 
    
    # calculate $ip
    #if [ -f $ip_file ]; then
    #    n=`cat $ip_file`
    #else
    #    n=1
    #    echo "IP number: $n" | adddate >> $log 
    #fi
    #n=$(($n+1))
    #ip=$(echo $podcidr | sed "s:0/24:$n:g")
    #echo $n > $ip_file
    #echo "IP $ip, number: $n" | adddate >> $log 

    rand=$(tr -dc 'A-F0-9' < /dev/urandom | head -c4)
    host_if_name="veth$rand"
    ip link add $CNI_IFNAME type veth peer name $host_if_name  --ignore-errors
    ip link set $host_ifname up  --ignore-errors

    mkdir -p /var/run/netns/
    ip link set $host_ifname master cni0
    ln -sfT $CNI_NETNS /var/run/netns/$CNI_CONTAINERID
    ip link set $CNI_IFNAME netns $CNI_CONTAINERID

    ip netns exec $CNI_CONTAINERID ip link set $CNI_IFNAME up
    ip netns exec $CNI_CONTAINERID ip addr add $ipam_pod_ip/24 dev $CNI_IFNAME
    ip netns exec $CNI_CONTAINERID ip route add default via $ipam_bridge_ip


    mac=$(ip netns exec $CNI_CONTAINERID ip link show eth0 | awk '/ether/ {print $2}')
    address="${ipam_pod_ip}/24"
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
    logger $output
    echo "$output"
	
    #exit 0	    
;;

# Deleting network from pod 
DEL)
    logger "ipam_netconf: $ipam_netconf"
    /opt/cni/bin/host-local <<<"$ipam_netconf"
    
    logger "rm -rf /var/run/netns/$CNI_CONTAINERID: $CNI_CONTAINERID" 
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

  logger "Unknown CNI_COMMAND: $CNI_COMMAND" 
  exit 1
;;

esac
