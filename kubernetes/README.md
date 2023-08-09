
10-k8s-cni-bash-plugin.conf -> /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

k8s-cni-bash-plugin.bash -> /opt/cni/bin/k8s-cni-bash-plugin


Troubleshooting

```console
export node=aks-nodepool1-25909977-vmss000000
kubectl debug node/${node} -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
```

inside pod

```console
chroot /host
journalctl -u kubelet 
```


kubectl -n kube-system  exec ds/k8s-cni-bash-plugin -it -- bash

kubectl -n kube-system  logs ds/k8s-cni-bash-plugin -c k8s-cni-bash-plugin-init

kubectl -n kube-system  logs ds/k8s-cni-bash-plugin -c k8s-cni-bash-plugin

Literature:
https://nicovibert.com/2022/10/03/how-to-ssh-into-aks-nodes-with-extra-privileges/


