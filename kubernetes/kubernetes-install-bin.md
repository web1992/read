# kubernetes install bin

`/usr/lib/systemd/system`

cat `kube-apiserver.service`

```conf
[Unit]
Description=Kubernetes  API Server
After=etcd.service
Wants=etcd.service

[Service]
Type=notify
EnvironmentFile=/etc/kubernetes/apiserver
ExecStart=/usr/bin/kube-apiserver $KUBE_API_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```conf
KUBE_API_ARGS="--etcd-servers=http://127.0.0.1:2379 \
--insecure-bind-address=0.0.0.0 \
--insecure-port=8080 \
--service-cluster-ip-range=169.169.0.0/16 \
--service-node-port-range=1-65535 \
--logtostderr=false \
--log-dir=/var/log/kubernetes \
--v=0 \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,PersistentVolumeClaimResize,RuntimeClass,CertificateApproval,CertificateSigning,CertificateSubjectRestriction,DefaultIngressClass,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"
```


`kube-controller-manager.service`

```conf
[Unit]
Description=Kubernetes Controller Server
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=/etc/kubernetes/controller-manager
ExecStart=/usr/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

`kube-controller-scheduler.service`

```conf
[Unit]
Description=Kubernetes Scheduler Server
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=/etc/kubernetes/scheduler
ExecStart=/usr/bin/kube-scheduler $KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

1q

systemctl enable kube-apiserver.service
systemctl start kube-apiserver.service
systemctl status kube-apiserver.service

systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager

systemctl enable kube-controller-scheduler
systemctl start kube-controller-scheduler
systemctl status kube-controller-scheduler

```yaml
apiVersion: v1
kind: Config
users:
- name: client
  user:
clusters:
- name: default
  cluster:
    server: http://127.0.0.1:8080
contexts:
- context:
    cluster: default
    user: client
  name: default
current-context: default
```

`~/.kube/config`

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJd01EWXlOREV4TlRFME9Wb1hEVE13TURZeU1qRXhOVEUwT1Zvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBT3ZGCmlpdkUxNGFtWEVZVkl6NXAyWGFYMG9lM2pZYUdha1puS0pBb0JhZlFCTTk1bklSUy9FdzhEWlBIU1VxWmdlQkQKeTNMcFY0TEZDQ2E5UWFvanhzYXlWSXJRU21yOWhoOW82ZFpXVjF1RzdEK2lrWEx5cExReGZhMXZkYWhOZ1NhTQo3cFQrTGl0cWdyQ0hjK09ETFFCU1pHaWZXQ0dmNlQ1MU0vNzRBNHNXWTJZbXkyTERBOU93bFdUdjBJMGNaMWdECmVoMEdmZUdMaWU0TCtmb28vTi8raE02YU4weXRsNUQvK3loT3JPWmhzYm44L1A5aXlLNnRWenY0N0NSQW9GVzgKUGNUNTJ2cVpDRWE5b0E0MzBxa01McDB0SlplVTByTm5RQjdvN0c3SFZxTm1OUlEyekhzNHVJMnpqend0V1EwZQpJZmlLUFduS1h0UnNJSlRwMFgwQ0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFCdzNkR2JFNUNMSTRYWDRWV2ptMmdpZis0c04KZC9uZzVpN3djVkJKeWIyRlZybU5zYUtPcDFpdDhwRGFla1FmU0p3d2VnOTMvK0VBcmtDb1NDZmI1ZE4ySldiKwpPUmt5QW1HSThRRVRWVGhMaVhSUWlYbnJ0dnBPdVh2WEpTNjhUblpyWnFGZnIrWkEzK1NvL2xzdnBZSXQxUjlxClZ6bU5xQUJHdjY1WG4xcmtVdURySG5PNjloZmMwQWdFY1FhL050d0xDSkxWbkVLQ3lWTDVCV0pJdWo0eUR6TXIKR00zUGkzTUx6b2lncWxIVDQ3V2E3bjRmL3pOSmVWcWxmRDVmU3I0Um4wbXJncjJMT0RpeVRCL3l6TDAxZjVXeAo1TDd6ZXl0NlNkZGIzYVlWZDF1OVBpQlBKUmNFQmlKUkZiQUhWd2o0cENKUkdoTlRZWTdpeXpXOWN1MD0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://81.68.100.22:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM4akNDQWRxZ0F3SUJBZ0lJWlhtWjhEMmY0WkF3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TURBMk1qUXhNVFV4TkRsYUZ3MHlNVEEyTWpReE1UVXhOVEZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXREVXlkeEl0alUzdTltMkkKLzVWUXpBTEJSRzBiSVIxYzVZY1h1MW1kbEREVEkzdGtQUjVVcU1UWW1mRmgrV3gxUG9jSWRsK0ErK3k2R25yNAp5dkZNQXNwTUxpZTdjcTFldG5PTC9ZWFppb0tkdmNEc1pnaHFjT2hieWswQTdneVJidDZSb2lhZWJSTGVJbmNlClVuZW10bzFZR0psQ2JYcHYwa0JwUENzeGI0ckNXLzY4YjhsMFFhaVJmZTdGVEJPNEVEUGp6b2xaZkFvYTVNOFMKTlRRa0UxNWVzM1NVbUFzVG1iM3NGS0NWYXlWTnhtL0dMVlEzeWVjSE11TldvYkh5QnBkemFLQnNLdnVocjU2Rgo5b3JsZ0RYTzFmLzl6T1V4R3lPVmZ5Q0htUjQvR0FlYVNKcDFtRm84WUk1ZU42TlNJWFdSZmtGcklJVUpCT2h5CjE5dTZ3UUlEQVFBQm95Y3dKVEFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFHOHdneUZoMXJSMHY3R0txWmxucDRGVU5HWEZ4Y2RiUExEVwoxNG9ZeFR5V1BDYVVQa1psZnllSEhpbHRUb05haW5ueUlIM0pQQnVHMnVMcndjVkdBNjI5dXFJYXo3ejR4M1JXCjBYZ2ZxWnljS2xyUnEvc29aM21EQ2RjTGo4SHBxSURGeWFsWlNSMlorbnRVY1ZLMWx1dTc4RDhubitGd1BPQ2wKWkxKUFJrZzN5WTNKdWRqOUZzbHhQVlllcEE2Y2FSVW9PbGVFL2s4bVgyM3RhSnJ2UXZ2QW9WaDQyYlJrQTZNVgo5UVdOcnBlK2RzWW9PUC9taGtOVUNQMTYwVVlZMTQ2Tm1XUmswVWFXVGNqcnkvK0R3eFpLbGRZbG91ZFZiendlCk5JYlJIMXROcWpaZFJPK3g4dUt3L2FGWld0ZlRTTksxeklRV2RpdWlxRTU3SExWZm5uYz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBdERVeWR4SXRqVTN1OW0ySS81VlF6QUxCUkcwYklSMWM1WWNYdTFtZGxERFRJM3RrClBSNVVxTVRZbWZGaCtXeDFQb2NJZGwrQSsreTZHbnI0eXZGTUFzcE1MaWU3Y3ExZXRuT0wvWVhaaW9LZHZjRHMKWmdocWNPaGJ5azBBN2d5UmJ0NlJvaWFlYlJMZUluY2VVbmVtdG8xWUdKbENiWHB2MGtCcFBDc3hiNHJDVy82OApiOGwwUWFpUmZlN0ZUQk80RURQanpvbFpmQW9hNU04U05UUWtFMTVlczNTVW1Bc1RtYjNzRktDVmF5Vk54bS9HCkxWUTN5ZWNITXVOV29iSHlCcGR6YUtCc0t2dWhyNTZGOW9ybGdEWE8xZi85ek9VeEd5T1ZmeUNIbVI0L0dBZWEKU0pwMW1GbzhZSTVlTjZOU0lYV1Jma0ZySUlVSkJPaHkxOXU2d1FJREFRQUJBb0lCQVFDbzBZa2tPUGhKZnUvVgpGWW9ZL1BXREdUV2E5NmRKbjJ0T2J2OFJlUU9CTnpnazdreGFZVmFvQURoMkJzWmsxbkVEa1phZzVoazhhR2x6CnN5M3RXSjEvbzZvNE51cUlwTmVzanBSZmZZdnRFUzNhL0tlNWNqcmM2U0JNWlZUd3JQOTFZTFlIdEt3SHZId3kKeDJxMWtQZXgzcm5mMlh0OGVnM1ZacGZ2VVB0djVIaDhSaHYzVmRuYXJObWExTnhlYzl6Q0NDbkRKWXJNSDR1RApRV05lYkRLSjVZMXM1MTA5VTUvcTZDK1JRN0NhQ01ETGRmeHZ4dHV1U21TeDk5azl0dWdCc3o0WTdyV2tHMFR3CkVSUWVGR09Wa2Niekx5d0NGdlBHWjdxT1Y3RnVyUE5VcWdiL1FDNE5vZ1N6cUNVc0xyR3o4Z25lRmFqekovc1EKMTNoWEVXMDlBb0dCQU5pSU85R2NQeFRFcldNQ3dUSXJJR1pGcGVHSnozNnRja2pPQ25CUE11azVHVW5kbmUzMApva3ZNdXFWeFc0RVZnb1dnTW5yemJFaEdYVjFsbTdFODVVbmtobHo0NjlVK0g3MzNQTW5yUmRvNVRlR3VsMHJDCi83YURSdzNYRjdsbUFoeGFESkZ0YkpVYjVma2dESVM5c3VzYmlCRGpTRUtIcmNGbEVWUEdPc0liQW9HQkFOVU8KQVhodXJ4L0czOENCa0dpbGMySWNxVGlvTVlOdm9uTm5YR0h6MFJVUTg0RHQ0dG5XOEhRdDFWSElGRDEwQ2p6TAo0ZXRFOTQvU2dPeHg3Rll1OG1iNWVDU2tVTXNSZjZlMlh6VDVQZXh2Q0tvMGYwcEU2QTFhZHVGd1FsazZwcjNLClpZT1ZHQU9IZmJqdmMrRzB1NUdCZWtidTlqWGZ5dzZ5SjltK3VTUlRBb0dBWXdBR3VaT0NrL0JJaGhoZ1ZKdTcKT0lkbmpITUIxNTFkdjBQVktmeEwvcTRJamVreHAvWk5yZkp3OCt1Y05xeXEvSVYrRHhEMDFTYTIwVmova2syUgpWL09RS3puME9ZOHAzQ1VLT2hmRDNENlBDVHhXRit5SUZkNTN3akF4dkthVEdIdGplNnBZRnVTbWhQek9QSEt2Ck55ZGpVclZYK0hNb1VsL3ZTQ285K3prQ2dZRUFyUTFqUkY4aS83eVpvZE9iYUdSN0JBWWpyVkZ3WmtJV3dZWUQKRTh6bTF5V2RvK3VWaHp0K3M5OUdsZGJlR2N4WFJHcVdabkx1WW5PcEpHU2tncHcvYUVUWndXbDE5bnVRSkxtTgpPNG4zTWtROTFZSXVvalMyQjZLalRSblJ5b2hKUjM5T1ZVS1U3c2p1NVhnWnVBc0ZEM3NMeHZIeUtuQk1qdk5HClN5Y1BXdUVDZ1lBUmd1UVI0U011WXNVQzkyTXd2ckFpVXpwTGNvM3U2VnRldE55dmRGQnhmVXM3VStOMmdLUkQKRVFmamhrbWNOOE9VdUxGcUM2ZGdsRS9IbVVnTGluYnl6WGkxSjNiNFUyVG1iMitmMnZDM2JpNGpNWHdTeFhadwpack84N2VEZlRyOEhnRjhWUkNuOU83VS92TkkrYlRRVXRvMVlvc3lwbVVXNFJGQmhaNlp6VFE9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

cat kubelet.service

```conf
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/kubernetes/kubelet
WorkingDirectory=/var/lib/kubelet
ExecStart=/usr/bin/kubelet $KUBELETE_ARGS
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```

cat kube-proxy.service

```conf
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
After=network.target
Requires=network.target

[Service]
EnvironmentFile=/etc/kubernetes/proxy
ExecStart=/usr/bin/kube-proxy $KUBE_PROXY_ARGS
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```

cat /etc/kubernetes/proxy

```conf
KUBE_PROXY_ARGS="--kubeconfig=/etc/kubernetes/kubeconfig \
--hostname-override=huawei \
--logtostderr=false \
--log-dir=/var/log/kubernetes \
--v=5"
```

cat /etc/kubernetes/kubelet

```conf
KUBELETE_ARGS="--kubeconfig=/etc/kubernetes/kubeconfig \
--hostname-override=huawei \
--logtostderr=false \
--log-dir=/var/log/kubernetes \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 \
--v=5"
```

openssl genrsa -out cs_client.key 2048

openssl req  -new  -key cs_client.key -subj "/CN=rourou.xyz" -days 10000 -out cs_client.csr


openssl x509 -req -in cs_client.csr   -CA ca.crt -CAkey ca.key -CAcreateserial -out cs_client.crt -days 10000


client-certificate: /etc/kubernetes/cs_client.crt
client-key: /etc/kubernetes/cs_client.key
certificate-authority: /etc/kubernetes/ca.crt


kubectl --server=https://81.68.100.22:6443 \
--client-certificate=/etc/kubernetes/cs_client.crt \
--client-key=/etc/kubernetes/cs_client.key \
--certificate-authority=/etc/kubernetes/ca.crt get nodes

openssl req -x509 -new -nodes -key ca.key -subj "/CN=rourou.xyz" -days 10000 -out ca.crt

```conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = CN
ST = CNST
L = SH
O = web1992
OU = web1992u
CN = 81.68.100.22

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 81.68.100.22
IP.2 = 169.169.0.1

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names

```

```conf
--client-ca-file=/etc/kubernetes/ca.crt \
--tls-private-key-file=/etc/kubernetes/server.key \
--tls-cert-file=/etc/kubernetes/server.crt \
--insecure-port=0 \
--secure-port=6443 \
```

## Link

- [https://kubernetes.io/zh/docs/concepts/cluster-administration/certificates/](https://kubernetes.io/zh/docs/concepts/cluster-administration/certificates/)
