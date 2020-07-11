# kubernetes install bin

k8s 集群的二进制安装 (OS: CentOS 7)

- [kubernetes install bin](#kubernetes-install-bin)
  - [Master](#master)
    - [kube-apiserver.service](#kube-apiserverservice)
    - [kube-controller-manager.service](#kube-controller-managerservice)
    - [kube-controller-scheduler.service](#kube-controller-schedulerservice)
    - [etcd.service](#etcdservice)
    - [docker.service](#dockerservice)
      - [install docker on centos](#install-docker-on-centos)
      - [设置镜像地址](#设置镜像地址)
    - [Master as Node](#master-as-node)
    - [flanneld.service](#flanneldservice)
  - [Node](#node)
    - [Node flanneld.service](#node-flanneldservice)
    - [Node docker.service](#node-dockerservice)
    - [kubectl](#kubectl)
    - [kubelet.service](#kubeletservice)
    - [kube-proxy.service](#kube-proxyservice)
  - [k8s 安全设置](#k8s-安全设置)
    - [Master 签发证书](#master-签发证书)
    - [Node 签发证书](#node-签发证书)
  - [常用命令](#常用命令)
  - [Link](#link)

## Master

Master 节点需要安装的服务

所有的服务都是基于 `systemd` 进行配置管理，安装之前需要知道 `systemd` 相关的知识,文末有链接

```sh
# pwd
/usr/lib/systemd/system

kube-apiserver.service
kube-controller-manager.service
kube-controller-scheduler.service
kubelet.service
kube-proxy.service
flanneld.service
docker.service
etcd.service
```

### kube-apiserver.service

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

### kube-controller-manager.service

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

### kube-controller-scheduler.service

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

### etcd.service

```conf
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd --enable-v2=true --listen-client-urls=http://0.0.0.0:2379 --advertise-client-urls=http://0.0.0.0:2379

[Install]
WantedBy=multi-user.target
```

### docker.service

#### install docker on centos

```sh
sudo yum check-update

curl -fsSL https://get.docker.com/ | sh

sudo systemctl start docker

sudo systemctl status docker

# Lastly, make sure it starts at every server reboot:
sudo systemctl enable docker

```

#### 设置镜像地址

`cat /etc/docker/daemon.json`

```json
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
```

### Master as Node

把 Master 也当做 Node 加入集群,需要安装下面的服务

- kubelet.service
- kube-proxy.service

需要执行下面的命令：

```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### flanneld.service

`flanneld` 安装的目的是为了让 Pod 直接进行通信

cat flanneld.service

```[Unit]
Description=Flanneld
Documentation=https://github.com/coreos/flannel
After=network.target
Before=docker.service

[Service]
ExecStart=/usr/bin/flanneld --etcd-endpoints=${FLANNELD_ETCD} --public-ip=81.68.100.22 --iface=eth0
EnvironmentFile=/etc/kubernetes/flanneld
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```sh
# cat /etc/kubernetes/flanneld
FLANNELD_ETCD="http://127.0.0.1:2379"
FLANNELD_OPTIONS="/coreos.com/network"
```

## Node

```sh
# pwd
/usr/lib/systemd/system

kubelet.service
kube-proxy.service
flanneld.service
docker.service
```

### Node flanneld.service

与 Master 安装 方式一致

### Node docker.service

与 Master 安装 方式一致

### kubectl

`kubectl` 是链接到 k8s 集群的命令行工具，如果集群使用了证书，就需要配置证书，否则不需要配置

`kubectl` 可以安装到任何机器上，安装之后，配置下集群地址就可以使用了

配置 `~/.kube/config`

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

### kubelet.service

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

### kube-proxy.service

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

## k8s 安全设置

### Master 签发证书

openssl genrsa -out cs_client.key 2048

openssl req  -new  -key cs_client.key -subj "/CN=rourou.xyz" -days 10000 -out cs_client.csr

openssl x509 -req -in cs_client.csr   -CA ca.crt -CAkey ca.key -CAcreateserial -out cs_client.crt -days 10000

client-certificate: /etc/kubernetes/cs_client.crt
client-key: /etc/kubernetes/cs_client.key
certificate-authority: /etc/kubernetes/ca.crt

### Node 签发证书

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
OU = web1992
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

## 常用命令

```sh
systemctl enable kube-apiserver.service
systemctl start kube-apiserver.service
systemctl status kube-apiserver.service

systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager

systemctl enable kube-controller-scheduler
systemctl start kube-controller-scheduler
systemctl status kube-controller-scheduler
```

## Link

- [systemd](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html)
- [https://kubernetes.io/zh/docs/concepts/cluster-administration/certificates/](https://kubernetes.io/zh/docs/concepts/cluster-administration/certificates/)
