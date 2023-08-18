# Create an iptables rule only if it doesn't yet exist
ensure() {
  eval "$(sed 's/-A/-C/' <<<"$@")" &>/dev/null || eval "$@"
}

#iptables_configuration() {
  # TODO 
#}

cniconf=abc

set -u
set -x
set -e



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


      # Create bridge only if it doesn't yet exist (default $bridge_interface)
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
      #ensure iptables -A FORWARD -s "$pod_network" -j ACCEPT
      
      logger "iptables -A FORWARD -d $pod_network -j ACCEPT"
      #ensure iptables -A FORWARD -d "$pod_network" -j ACCEPT

      # Set up NAT for traffic leaving the cluster (replace Pod IP with node IP)
      logger "Set up NAT for traffic leaving the cluster (replace Pod IP with node IP): $pod_cidr -> $host_network"
      
      #logger "iptables -t nat -N $my_cni_masquerade &>/dev/null"
      #if iptables -t nat -N "$my_cni_masquerade" &>/dev/null; then
      #  iptables -t nat -N "$my_cni_masquerade"
      #else
      #  logger "Not needed to add chain iptables -t nat -N  : $my_cni_masquerade "
      #fi

      #is_cni_maskarade_added=$(iptables -L -t nat |grep ${my_cni_masquerade})
      #logger "is_cni_maskarade_added: $is_cni_maskarade_added"	
      # if [ -z "$is_cni_maskarade_added" ]
      #	then
      # 	  iptables -t nat -N "$my_cni_masquerade"
      #	else
      #	      logger "Not needed to add chain iptables -t nat -N  : $my_cni_masquerade "
      #	fi
      

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
