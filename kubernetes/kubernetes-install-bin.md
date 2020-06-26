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
    certificate-authority:aaa
    server: https://192.167.0.1:6443
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
    client-certificate: aa
    client-key: aa
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


kubectl --server=https://192.168.1.10:6443 \
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
CN = 192.168.1.10

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 192.168.1.10
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
