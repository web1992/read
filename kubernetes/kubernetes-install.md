# kubernetes install

## install docker on centos

```sh
sudo yum check-update

curl -fsSL https://get.docker.com/ | sh

sudo systemctl start docker

sudo systemctl status docker

# Lastly, make sure it starts at every server reboot:
sudo systemctl enable docker

```

## 设置镜像地址

`cat /etc/docker/daemon.json`

```json
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
```

## install kubernetes on centos

> /etc/yum.repos.d/kubernetes.repo

```repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
```

```sh
#yum install kubectl kubelet kubernetes-cni kubeadm
yum install  kubelet kubeadm kubectl --disableexcludes=kubernetes
```

> init.default.yaml

```sh
kubeadm config print init-defaults > init.default.yaml
```

```yaml
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 1.2.3.4
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: tengxunyun
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
#imageRepository: docker.io/dustise
kind: ClusterConfiguration
kubernetesVersion: v1.18.0
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
scheduler: {}
```

## kubernetes master install

> init-config.yaml

```yaml
# master config
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
localAPIEndpoint:
  advertiseAddress: 81.68.100.22
  bindPort: 6443
kind: ClusterConfiguration
kubernetesVersion: v1.18.0
networking:
  podSubnet: 192.168.0.0/16
```

```sh
sudo systemctl enable kubelet && sudo systemctl start kubelet
```

```sh
kubeadm config images pull --config=init-config.yaml
#kubeadm init --config=init-config.yaml
# ignore error
kubeadm init --config=init-config.yaml --ignore-preflight-errors=NumCPU --v=5
```

```sh
W0620 17:48:29.060392   32394 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[init] Using Kubernetes version: v1.18.0
[preflight] Running pre-flight checks
	[WARNING NumCPU]: the number of available CPUs 1 is less than the required 2
	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [tengxunyun kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.17.0.11]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [tengxunyun localhost] and IPs [172.17.0.11 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [tengxunyun localhost] and IPs [172.17.0.11 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
W0620 17:48:32.532053   32394 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[control-plane] Creating static Pod manifest for "kube-scheduler"
W0620 17:48:32.533418   32394 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 25.501704 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.18" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node tengxunyun as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node tengxunyun as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: aaa.xxxxx
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.17.0.11:6443 --token 12313.12313 \
    --discovery-token-ca-cert-hash sha256:asdasd
```

```sh
kubectl get -n kube-system configmap
```

## kubernetes node install

```yaml
# node config
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: 81.68.100.22:6443
    token: aaa.xxx
    unsafeSkipCAVerification: true
  tlsBootstrapToken: aaa.xxx
```

kubeadm join --config=init-node.yaml

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

```log
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created
```

```sh
[root@tengxunyun ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                 READY   STATUS              RESTARTS   AGE
kube-system   coredns-546565776c-2twdl             0/1     Pending             0          87m
kube-system   coredns-546565776c-ffxb6             0/1     Pending             0          87m
kube-system   etcd-tengxunyun                      1/1     Running             0          87m
kube-system   kube-apiserver-tengxunyun            1/1     Running             0          87m
kube-system   kube-controller-manager-tengxunyun   1/1     Running             0          87m
kube-system   kube-proxy-98j88                     1/1     Running             0          87m
kube-system   kube-scheduler-tengxunyun            1/1     Running             0          87m
kube-system   weave-net-zc5qz                      0/2     ContainerCreating   0          51s

# 安装 eave-net 之后

[root@aaa ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE
kube-system   coredns-546565776c-2twdl             1/1     Running   0          112m
kube-system   coredns-546565776c-ffxb6             1/1     Running   0          112m
kube-system   etcd-tengxunyun                      1/1     Running   0          113m
kube-system   kube-apiserver-tengxunyun            1/1     Running   0          113m
kube-system   kube-controller-manager-tengxunyun   1/1     Running   0          113m
kube-system   kube-proxy-98j88                     1/1     Running   0          112m
kube-system   kube-scheduler-tengxunyun            1/1     Running   0          113m
kube-system   weave-net-zc5qz                      2/2     Running   0          26m
```

kubectl get pods --all-namespaces
kubectl --namespace=kube-system describe pod
kubeadm reset
kubeadm init
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get  pod kube-apiserver-rourou.xyz --namespace=kube-system -o yaml

kubeadm init --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers --apiserver-advertise-address=81.68.100.22 --kubernetes-version=v1.18.0 --v=5 --ignore-preflight-errors=NumCPU

systemctl status kubelet
journalctl -xeu kubelet
docker ps -a | grep kube | grep -v pause
docker logs CONTAINERID

kubectl get configmap  --namespace=kube-system

kubectl  describe configmap  aaaxxx --namespace=kube-system

kubectl  replace -f kubeadm-config.yaml --namespace=kube-system

kubectl  get configmap  kubeadm-config   --namespace=kube-system  -o yaml > kubeadm-config.yaml
