# Create an iptables rule only if it doesn't yet exist
ensure() {
  eval "$(sed 's/-A/-C/' <<<"$@")" &>/dev/null || eval "$@"
}

#iptables_configuration() {
  # TODO 
#}

cniconf=`cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf`

my_cni_masquerade=K8S-CNI-BASH

set -u
#set -x
set -e
set -o pipefail


# Read cni configuration file
host_network=$(echo $cniconf | jq -r ".host_network")
pod_network=$(echo $cniconf | jq -r ".pod_network")
bridge_interface=$(echo $cniconf | jq -r ".bridge")
pod_cidr=$(echo $cniconf | jq -r ".pod_cidr")
pod_cidr_gw=$(echo $pod_cidr | sed "s:0/24:1:g")
subnet_mask_size=$(echo $pod_cidr | awk -F  "/" '{print $2}')
service_cidr=$(echo $cniconf | jq -r ".service_cidr")
coredns_ip=$(echo $cniconf | jq -r ".coredns_ip")

#echo "Flushing iptables rules"
#iptables -F

# Allow forwarding of packets in default network namespace to/from Pods
  echo "Allow forwarding of packets in default network namespace to/from Pods: $pod_network"
      
  echo "iptables -A FORWARD -s $pod_network -j ACCEPT"
  ensure iptables -A FORWARD -s "$pod_network" -j ACCEPT
      
  echo "iptables -A FORWARD -d $pod_network -j ACCEPT"
  ensure iptables -A FORWARD -d "$pod_network" -j ACCEPT

  # Set up NAT for traffic leaving the cluster (replace Pod IP with node IP)
  echo "Set up NAT for traffic leaving the cluster (replace Pod IP with node IP): $pod_cidr -> $host_network"
      
  
  set  +e
  echo "iptables -t nat -N $my_cni_masquerade"
  iptables -t nat -N "$my_cni_masquerade"
  set -e 
  
  echo "iptables -t nat -A $my_cni_masquerade -d $host_network -j RETURN"
  ensure iptables -t nat -A "$my_cni_masquerade" -d "$host_network" -j RETURN
      
  echo "iptables -t nat -A "$my_cni_masquerade" -d $pod_network -j RETURN"
  ensure iptables -t nat -A "$my_cni_masquerade" -d "$pod_network" -j RETURN
      
  echo "iptables -t nat -A $my_cni_masquerade -j MASQUERADE"
  ensure iptables -t nat -A "$my_cni_masquerade" -j MASQUERADE
      
  echo "iptables -t nat -A POSTROUTING -s $pod_cidr -j $my_cni_masquerade"
  ensure iptables -t nat -A POSTROUTING -s "$pod_cidr" -j "$my_cni_masquerade"
      
  # Allow outgoing internet 
  echo "iptables -t nat -A POSTROUTING -s $pod_cidr ! -o $bridge_interface -j MASQUERADE"
  ensure iptables -t nat -A POSTROUTING -s "$pod_cidr" ! -o "$bridge_interface" -j MASQUERADE
      
  iptables -L --line-numbers -v
  iptables -t nat -nvL
