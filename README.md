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
```
<pre>
  TODO
</pre>



[![cni bash pipeline](https://github.com/djkormo/k8s-cni-bash-plugin/actions/workflows/build-all.yml/badge.svg)](https://github.com/djkormo/k8s-cni-bash-plugin/actions/workflows/build-all.yml)
