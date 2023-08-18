#!/bin/bash -e

if [[ ${DEBUG} -gt 0 ]]; then set -x; fi

my_cni_masquerade=K8S-CNI-BASH
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


# Create an iptables rule only if it doesn't yet exist
ensure() {
  eval "$(sed 's/-A/-C/' <<<"$@")" &>/dev/null || eval "$@"
}

#iptables_configuration() {
  # TODO 
#}

#exec 3>&1 # make stdout available as fd 3 for the result
log=/var/log/cni.log #$CNI_LOGFILE # TODO , should be based on env 
cniconf=`cat /dev/stdin`

logger "CNI_CONFIG: $cniconf" 
logger "PATH: ${PATH}"
logger "CNI_LOGFILE: ${CNI_LOGFILE}"

#set -u
#set -e
set -x
#set -o pipefail
# example of  cni configuration
#    {
#        "cniVersion": "0.3.1",
#        "name": "k8s-cni-bash-plugin",
#        "type": "k8s-cni-bash-plugin",
#        "bridge": "cni0",
#        "host_network": "10.244.0.0/16",
#        "pod_network": "10.240.0.0/16",
#        "pod_cidr": "10.240.x.0/24"
#    }

# Read cni configuration file
host_network=$(echo $cniconf | jq -r ".host_network")
pod_network=$(echo $cniconf | jq -r ".pod_network")
bridge_interface=$(echo $cniconf | jq -r ".bridge")
pod_cidr=$(echo $cniconf | jq -r ".pod_cidr")
pod_cidr_gw=$(echo $pod_cidr | sed "s:0/24:1:g")
subnet_mask_size=$(echo $pod_cidr | awk -F  "/" '{print $2}')
service_cidr=$(echo $cniconf | jq -r ".service_cidr")
coredns_ip=$(echo $cniconf | jq -r ".coredns_ip")
# Prepare NetConf for host-local IPAM plugin (add 'ipam' field)
ipam_netconf=$(jq ". += {ipam:{subnet:\"$pod_cidr\", gateway:\"$pod_cidr_gw\"}}" <<<"$cniconf")

#logger "ipam_netconf: $ipam_netconf"
logger "CNI_COMMAND=$CNI_COMMAND, CNI_CONTAINERID=$CNI_CONTAINERID, CNI_NETNS=$CNI_NETNS, CNI_IFNAME=$CNI_IFNAME, CNI_ARGS=$CNI_ARGS, CNI_PATH=$CNI_PATH\n$cniconf\n$ipam_netconf"

case $CNI_COMMAND in
# Adding network to pod 

ADD)
# Invoke host-local IPAM plugin to allocate IP address for Pod 
    # Example response:
    # {
    #   "cniVersion": "0.3.1",
    #   "ips": [
    #     {
    #       "version": "4",
    #       "address": "200.200.0.2/24",
    #       "gateway": "200.200.0.1"
    #     }
    #   ],
    #   "dns": {}
    # }
    logger "CNI_COMMAND : $CNI_COMMAND start"
    ipam_response=$(/opt/cni/bin/host-local <<<"$ipam_netconf")
    logger "ipam_response: $ipam_response"
    # Extract IP addresses for Pod and gateway (bridge) from IPAM response
    ipam_pod_ip=$(jq -r '.ips[0].address' <<<"$ipam_response")
    ipam_bridge_ip=$(jq -r '.ips[0].gateway' <<<"$ipam_response")
    ipam_code=$(jq -r '.code' <<<"$ipam_response")
    ipam_msg=$(jq -r '.msg' <<<"$ipam_response")
    logger "ipam_code: $ipam_code, ipam_msg: $ipam_msg"


 # The lock provides mutual exclusivity (at most one process in the critical
    # section) and synchronisation (no process reaches the Pod-specific setup
    # before the one-time setup has been fully completed at least once).
    {
      # Acquire lock, or wait if it is already taken
      flock 100

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      # Begin of critical section
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

      # Create bridge only if it doesn't yet exist (default cni0)
      if ! ip link show $bridge_interface &>/dev/null; then
        ip link add $bridge_interface type bridge
        ip address add "$ipam_bridge_ip/24" dev $bridge_interface
        ip link set $bridge_interface up
      
      else
        logger "Not needed to configure bridge : $bridge_interface with IP $ipam_bridge_ip/24"
      fi	
    
      # Allow forwarding of packets in default network namespace to/from Pods
      logger "Allow forwarding of packets in default network namespace to/from Pods: $pod_network"
      
      logger "iptables -A FORWARD -s $pod_network -j ACCEPT"
      ensure iptables -A FORWARD -s "$pod_network" -j ACCEPT
      
      logger "iptables -A FORWARD -d $pod_network -j ACCEPT"
      ensure iptables -A FORWARD -d "$pod_network" -j ACCEPT

      # Set up NAT for traffic leaving the cluster (replace Pod IP with node IP)
      logger "Set up NAT for traffic leaving the cluster (replace Pod IP with node IP): $pod_cidr -> $host_network"
      
      logger "iptables -t nat -N $my_cni_masquerade &>/dev/null"
      
      # Bypass for existing chain
      set +e
      iptables -t nat -N $my_cni_masquerade &>/dev/null
      set -e
      
      logger "iptables -t nat -A $my_cni_masquerade -d $host_network -j RETURN"
      #ensure iptables -t nat -A "$my_cni_masquerade" -d "$host_network" -j RETURN
      
      logger "iptables -t nat -A "$my_cni_masquerade" -d $pod_network -j RETURN"
      #ensure iptables -t nat -A "$my_cni_masquerade" -d "$pod_network" -j RETURN
      
      logger "iptables -t nat -A "$my_cni_masquerade" -j MASQUERADE"
      #ensure iptables -t nat -A "$my_cni_masquerade" -j MASQUERADE
      
      logger "iptables -t nat -A POSTROUTING -s $pod_cidr -j $my_cni_masquerade"
      #ensure iptables -t nat -A POSTROUTING -s "$pod_cidr" -j "$my_cni_masquerade"
      
      # Allow outgoing internet 
      logger "iptables -t nat -A POSTROUTING -s $pod_cidr ! -o $bridge_interface -j MASQUERADE"
      #ensure iptables -t nat -A POSTROUTING -s "$pod_cidr" ! -o "$bridge_interface" -j MASQUERADE"

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      # End of critical section
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      logger "End of critical section: $pod_cidr ->  $pod_network -> $host_network"
    }  100>/tmp/k8s-cni-bash-plugin.lock

    #--------------------------------------------------------------------------#
    # Display all input paramneters
    #--------------------------------------------------------------------------#
    logger "CNI_COMMAND: $CNI_COMMAND configuration"
    logger "CNI_COMMAND:  $CNI_COMMAND"
    logger "Adding IP for Pod CIDR: $pod_cidr"  
    logger "GatewayIP $pod_cidr_gw" 
    logger "IP Mask $subnet_mask_size" 
    logger "CNI_IFNAME: $CNI_IFNAME" 
    logger "CNI_NETNS: $CNI_NETNS"  
    logger "CNI_CONTAINERID: $CNI_CONTAINERID" 
    logger "IPAM pod_ip: $ipam_pod_ip" 
    logger "IPAM bridge_ip: $ipam_bridge_ip" 
    logger "IPAM code: $ipam_code" 
    logger "IPAM msg: $ipam_msg" 
    
    # randomize interface suffix
    rand=$(tr -dc 'A-F0-9' < /dev/urandom | head -c4)
    host_if_name="veth$rand"
    #--------------------------------------------------------------------------#
    # Do Pod-specific setup
    #--------------------------------------------------------------------------#

    # Create named link to Pod network namespace (for 'ip' command)
    logger "linking CNI_NETNS to: $CNI_CONTAINERID"
    mkdir -p /var/run/netns/
    ln -sf "$CNI_NETNS" /var/run/netns/"$CNI_CONTAINERID"

    # Create veth pair in Pod network namespace
    logger "Create veth pair in Pod network namespace: ip netns exec $CNI_CONTAINERID ip link add "$CNI_IFNAME" type veth peer name $host_ifname"
    rand=$(tr -dc 'A-F0-9' < /dev/urandom | head -c4)
    host_ifname=veth$rand
    host_ifname=veth$RANDOM
    ip netns exec "$CNI_CONTAINERID" ip link add "$CNI_IFNAME" type veth peer name "$host_ifname"
    
    
    # Move host-end of veth pair to default network namespace and connect to bridge
    logger "Move host-end of veth pair to default network namespace and connect to bridge $bridge_interface to: $CNI_CONTAINERID"
    ip netns exec "$CNI_CONTAINERID" ip link set $host_ifname netns 1
    ip link set $host_ifname master $bridge_interface up
	
    # Assign IP address selected by IPAM plugin to Pod-end of veth pair
    logger "Assign IP $ipam_pod_ip address selected by IPAM plugin to Pod-end of veth pair to: $CNI_CONTAINERID"
    ip netns exec "$CNI_CONTAINERID" ip address add $ipam_pod_ip dev "$CNI_IFNAME"
    ip netns exec "$CNI_CONTAINERID" ip link set "$CNI_IFNAME" up
    
    # Create default route to bridge in Pod network namespace
    logger "Create default route to bridge in Pod with IP $ipam_bridge_ip network namespace: $CNI_CONTAINERID"
    ip netns exec "$CNI_CONTAINERID" ip route add default via $ipam_bridge_ip dev $CNI_IFNAME

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
 
    #--------------------------------------------------------------------------#
    # Return response
    #--------------------------------------------------------------------------#
    
   # Create response by adding 'interfaces' field to response of IPAM plugin 
    response=$(jq ". += {interfaces:[{name:\"$CNI_IFNAME\",sandbox:\"$CNI_NETNS\"}]} | .ips[0] += {interface:0}" <<<"$ipam_response")
    logger "Ipam response:\n$response"
    logger "CNI_COMMAND : $CNI_COMMAND end"
    echo "$response" >&3
	    
;;

# Deleting network from pod 
DEL)
    logger "CNI_COMMAND : $CNI_COMMAND start"
    logger "ipam_netconf: $ipam_netconf"
    /opt/cni/bin/host-local <<<"$ipam_netconf"
    
    logger "rm -rf /var/run/netns/$CNI_CONTAINERID: $CNI_CONTAINERID" 
    rm -rf /var/run/netns/$CNI_CONTAINERID
    logger "CNI_COMMAND : $CNI_COMMAND end"
    
;;

CHECK)
logger "CNI_COMMAND : $CNI_COMMAND start"
logger "CNI_COMMAND : $CNI_COMMAND end"
;;

VERSION)
logger "CNI_COMMAND : $CNI_COMMAND start"
echo '{
  "cniVersion": "0.3.1", 
  "supportedVersions": [ "0.3.0", "0.3.1", "0.4.0" ] 
}'
logger "CNI_COMMAND : $CNI_COMMAND end"
;;

*)
  logger "CNI_COMMAND : $CNI_COMMAND start"
  logger "Unknown CNI_COMMAND: $CNI_COMMAND" 
  logger "CNI_COMMAND : $CNI_COMMAND end"
  exit 1
;;

esac
