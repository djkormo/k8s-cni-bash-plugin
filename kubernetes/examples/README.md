```console
kubectl -n default get pod -o wide
```

<pre>
NAME                                           READY   STATUS    RESTARTS   AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
chess-ai-deployment-5cb7684455-vbfhv           1/1     Running   0          4m28s   10.240.4.12   aks-nodepool1-31571454-vmss000004   <none>           <none>
nginx-deployment-7fb96c846b-nz5mt              1/1     Running   0          4m27s   10.240.5.6    aks-nodepool1-31571454-vmss000005   <none>           <none>
nginx-deployment-7fb96c846b-sn844              1/1     Running   0          4m27s   10.240.3.13   aks-nodepool1-31571454-vmss000003   <none>           <none>
tool-pod                                       1/1     Running   0          4m27s   10.240.4.13   aks-nodepool1-31571454-vmss000004   <none>           <none>
ubuntu-net-utils-deployment-7bc987fcb5-7jxxg   1/1     Running   0          4m27s   10.240.3.14   aks-nodepool1-31571454-vmss000003   <none>           <none>
ubuntu-net-utils-deployment-7bc987fcb5-tqjsw   1/1     Running   0          4m27s   10.240.5.7    aks-nodepool1-31571454-vmss000005   <none>           <none>
</pre>

```console
kubectl -n default exec -it ubuntu-net-utils-deployment-7bc987fcb5-7jxxg --  bash
```

Inside 

My IP

```
ping 10.240.3.14
PING 10.240.3.14 (10.240.3.14) 56(84) bytes of data.
64 bytes from 10.240.3.14: icmp_seq=1 ttl=64 time=0.023 ms
64 bytes from 10.240.3.14: icmp_seq=2 ttl=64 time=0.047 ms
```

IP on the same node 
```
ping 10.240.3.13
PING 10.240.3.13 (10.240.3.13) 56(84) bytes of data.
64 bytes from 10.240.3.13: icmp_seq=1 ttl=64 time=0.111 ms
64 bytes from 10.240.3.13: icmp_seq=2 ttl=64 time=0.083 m
```

IP on different node 
```
ping  10.240.5.7
PING 10.240.5.7 (10.240.5.7) 56(84) bytes of data.
```


External IP 
```
ping portal.azure.com
ping: unknown host portal.azure.com
```


```
kubectl -n default exec tool-pod -- nslookup portal.azure.com
```

<pre>
Server:         10.0.0.10
Address:        10.0.0.10:53

Non-authoritative answer:
portal.azure.com        canonical name = portal.azure.com.trafficmanager.net
portal.azure.com.trafficmanager.net     canonical name = dual.part-0024.t-0009.t-msedge.net
dual.part-0024.t-0009.t-msedge.net      canonical name = part-0024.t-0009.t-msedge.net
Name:   part-0024.t-0009.t-msedge.net
Address: 2620:1ec:46::52
Name:   part-0024.t-0009.t-msedge.net
Address: 2620:1ec:bdf::52

Non-authoritative answer:
portal.azure.com        canonical name = portal.azure.com.trafficmanager.net
portal.azure.com.trafficmanager.net     canonical name = dual.part-0024.t-0009.t-msedge.net
dual.part-0024.t-0009.t-msedge.net      canonical name = part-0024.t-0009.t-msedge.net
Name:   part-0024.t-0009.t-msedge.net
Address: 13.107.246.52
Name:   part-0024.t-0
</pre>


