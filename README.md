# k8s-cni-bash-plugin
Creating bash cni plugin for internal lab

Before

```console
kubectl get nodes
kubectl get node -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[?(@.type=="Ready")].message'
kubectl  get pod -o wide  -A
```

<pre>

NAME                                STATUS     ROLES   AGE     VERSION
aks-nodepool1-38495471-vmss000003   NotReady   agent   7h43m   v1.25.11
aks-nodepool1-38495471-vmss000004   NotReady   agent   7h43m   v1.25.11
E0821 19:30:34.108430     193 memcache.go:287] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
E0821 19:30:34.148513     193 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
E0821 19:30:34.166841     193 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
E0821 19:30:34.185701     193 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
  
NAME                                STATUS
aks-nodepool1-38495471-vmss000003   container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
aks-nodepool1-38495471-vmss000004   container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized



NAMESPACE     NAME                                           READY   STATUS    RESTARTS         AGE     IP           NODE                                NOMINATED NODE   READINESS GATES
kube-system   cloud-node-manager-644qs                       1/1     Running   1 (6h17m ago)    7h38m   10.224.0.6   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   cloud-node-manager-cg6s9                       1/1     Running   5 (6h35m ago)    7h38m   10.224.0.5   aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   coredns-autoscaler-569f6ff56-7qv5x             0/1     Pending   0                7h38m   <none>       <none>                              <none>           <none>
kube-system   coredns-fb6b9d95f-g2n4f                        0/1     Pending   0                7h38m   <none>       <none>                              <none>           <none>
kube-system   coredns-fb6b9d95f-xrflq                        0/1     Pending   0                7h38m   <none>       <none>                              <none>           <none>
kube-system   csi-azuredisk-node-wngd2                       3/3     Running   3 (6h17m ago)    7h38m   10.224.0.6   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   csi-azuredisk-node-xhbf7                       3/3     Running   15 (6h35m ago)   7h38m   10.224.0.5   aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   csi-azurefile-node-pslw6                       3/3     Running   3 (6h17m ago)    7h38m   10.224.0.6   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   csi-azurefile-node-vhpkv                       3/3     Running   15 (6h35m ago)   7h38m   10.224.0.5   aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   konnectivity-agent-6bc6567967-bkx62            1/1     Running   5 (6h35m ago)    7h38m   10.224.0.5   aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   konnectivity-agent-6bc6567967-ldm2c            1/1     Running   1 (6h17m ago)    7h38m   10.224.0.6   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   kube-proxy-fhzbm                               1/1     Running   5 (6h35m ago)    7h38m   10.224.0.5   aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   kube-proxy-ld7kx                               1/1     Running   1 (6h17m ago)    7h38m   10.224.0.6   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   metrics-server-657f59948c-8j9sh                0/2     Pending   0                7h38m   <none>       <none>                              <none>           <none>
kube-system   metrics-server-657f59948c-f7tvh                0/2     Pending   0                7h38m   <none>       <none>                              <none>           <none>

  
</pre>


After
```console
kubectl get nodes
kubectl get node -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[?(@.type=="Ready")].message'
kubectl  get pod -o wide  -A

kubectl top nodes
kubectl top pod -A

```
<pre>
NAME                                STATUS   ROLES   AGE     VERSION
aks-nodepool1-38495471-vmss000003   Ready    agent   7h59m   v1.25.11
aks-nodepool1-38495471-vmss000004   Ready    agent   7h59m   v1.25.11

NAME                                STATUS
aks-nodepool1-38495471-vmss000003   kubelet is posting ready status. AppArmor enabled
aks-nodepool1-38495471-vmss000004   kubelet is posting ready status. AppArmor enabled

NAMESPACE     NAME                                  READY   STATUS    RESTARTS     AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
kube-system   cloud-node-manager-4znh7              1/1     Running   0            3m3s    10.224.0.6    aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   cloud-node-manager-h2j7x              1/1     Running   0            3m6s    10.224.0.5    aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   coredns-76686c844b-cflhk              1/1     Running   0            3m9s    10.240.3.12   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   coredns-76686c844b-jjk2z              1/1     Running   0            3m9s    10.240.3.14   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   coredns-autoscaler-69c6d9f8c7-7wtcz   1/1     Running   0            3m9s    10.240.3.15   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   csi-azuredisk-node-59dz8              3/3     Running   0            3m1s    10.224.0.5    aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   csi-azuredisk-node-vfxpk              3/3     Running   0            3m4s    10.224.0.6    aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   csi-azurefile-node-bqqrv              3/3     Running   0            3m3s    10.224.0.5    aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   csi-azurefile-node-sl8sc              3/3     Running   0            3m2s    10.224.0.6    aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   k8s-cni-bash-plugin-hvlw4             1/1     Running   0            2m37s   10.224.0.6    aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   k8s-cni-bash-plugin-n7jmb             1/1     Running   0            2m37s   10.224.0.5    aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   konnectivity-agent-666cdd56fb-cb7g8   1/1     Running   0            3m9s    10.224.0.5    aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   konnectivity-agent-666cdd56fb-mcv8l   1/1     Running   0            3m9s    10.224.0.6    aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   kube-proxy-747vp                      1/1     Running   0            3m1s    10.224.0.6    aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   kube-proxy-8tkz4                      1/1     Running   0            3m      10.224.0.5    aks-nodepool1-38495471-vmss000004   <none>           <none>
kube-system   metrics-server-5c7bd6cccd-rd99c       2/2     Running   0            3m9s    10.240.3.13   aks-nodepool1-38495471-vmss000003   <none>           <none>
kube-system   metrics-server-5c7bd6cccd-rmdjm       1/2     Running   3 (4s ago)   3m9s    10.240.4.20   aks-nodepool1-38495471-vmss000004   <none>           <none>  


NAME                                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
aks-nodepool1-38495471-vmss000003   141m         7%     1320Mi          61%       
aks-nodepool1-38495471-vmss000004   167m         8%     1065Mi          49%     
  
NAMESPACE     NAME                                  CPU(cores)   MEMORY(bytes)   
kube-system   cloud-node-manager-4znh7              1m           16Mi            
kube-system   cloud-node-manager-h2j7x              1m           17Mi            
kube-system   coredns-76686c844b-cflhk              2m           13Mi            
kube-system   coredns-76686c844b-jjk2z              2m           13Mi            
kube-system   coredns-autoscaler-69c6d9f8c7-7wtcz   1m           8Mi             
kube-system   csi-azuredisk-node-59dz8              2m           22Mi            
kube-system   csi-azuredisk-node-vfxpk              2m           42Mi            
kube-system   csi-azurefile-node-bqqrv              2m           34Mi            
kube-system   csi-azurefile-node-sl8sc              2m           20Mi            
kube-system   k8s-cni-bash-plugin-hvlw4             0m           0Mi             
kube-system   k8s-cni-bash-plugin-n7jmb             0m           0Mi             
kube-system   konnectivity-agent-666cdd56fb-cb7g8   2m           14Mi            
kube-system   konnectivity-agent-666cdd56fb-mcv8l   1m           12Mi            
kube-system   kube-proxy-747vp                      1m           13Mi            
kube-system   kube-proxy-8tkz4                      1m           11Mi            
kube-system   metrics-server-5c7bd6cccd-rd99c       3m           24Mi            
kube-system   metrics-server-5c7bd6cccd-rmdjm       1m           7Mi 

  
</pre>



[![cni bash pipeline](https://github.com/djkormo/k8s-cni-bash-plugin/actions/workflows/build-all.yml/badge.svg)](https://github.com/djkormo/k8s-cni-bash-plugin/actions/workflows/build-all.yml)
