# kube-flannel

- [https://www.cnblogs.com/breezey/p/9419612.html](https://www.cnblogs.com/breezey/p/9419612.html)

```sh
# etcdctl put /coreos.com/network/config '{ "Network": "10.0.0.0/16" }'

# etcdctl get /coreos.com/network/config

# export ETCDCTL_API=2

# etcdctl ls /coreos.com/network/subnets

/coreos.com/network/subnets/10.0.4.0-24
/coreos.com/network/subnets/10.0.10.0-24
/coreos.com/network/subnets/10.0.9.0-24
/coreos.com/network/subnets/10.0.15.0-24

# etcdctl get /coreos.com/network/subnets/10.0.4.0-24

{"PublicIP":"172.31.78.120","BackendType":"vxlan","BackendData":{"VtepMAC":"82:49:e1:09:fa:86"}}

# etcdctl get /coreos.com/network/subnets/10.0.10.0-24

{"PublicIP":"172.17.0.11","BackendType":"vxlan","BackendData":{"VtepMAC":"da:06:4e:48:0b:9b"}}

```

```sh
systemctl daemon-reload
systemctl restart flanneld
systemctl status flanneld
```

cat flanneld.service

```conf
[Unit]
Description=Flanneld
Documentation=https://github.com/coreos/flannel
After=network.target
Before=docker.service

[Service]
ExecStart=/usr/bin/flanneld --etcd-endpoints=${FLANNELD_ETCD} --public-ip=118.190.146.22 --iface=eth0
EnvironmentFile=/etc/kubernetes/flanneld
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```sh
docker run -it busybox
```
