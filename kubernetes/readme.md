# Kubernetes

- [Kubernetes](#kubernetes)
  - [Kubernetes 设计目的](#kubernetes-%e8%ae%be%e8%ae%a1%e7%9b%ae%e7%9a%84)
  - [核心功能](#%e6%a0%b8%e5%bf%83%e5%8a%9f%e8%83%bd)
  - [kubernets 架构](#kubernets-%e6%9e%b6%e6%9e%84)
    - [Master](#master)
    - [Node](#node)
    - [Pod](#pod)
    - [Deployment](#deployment)
  - [Job CronJob](#job-cronjob)
  - [Daemon Set](#daemon-set)
  - [ConfigMap](#configmap)
    - [Sidecar](#sidecar)
  - [kubernets 资源](#kubernets-%e8%b5%84%e6%ba%90)
  - [kubernets 控制运行](#kubernets-%e6%8e%a7%e5%88%b6%e8%bf%90%e8%a1%8c)
  - [Links](#links)

## Kubernetes 设计目的

自动化容器编排平台

- 部署
- 弹性
- 管理

## 核心功能

- 服务发现与负载均衡
- 容器自动装箱
- 存储编排
- 自动容器恢复
- 自动发布与回滚
- 配置与密文管理
- 批量执行
- 水平伸缩

- 调度
- 自动恢复
- 水平伸缩

## kubernets 架构

![k8s](./images/k8s.png)

### Master

![k8s-master](./images/k8s-master.png)

### Node

![k8s-node](./images/k8s-node.png)

### Pod

Pod 解决的核心问题：容器之间高效的共享某些`资源`和`数据`

- 共享网络 Infra container
- 共享存储 Volumes shared-data

例子：War + Tomcat 应用部署

InitContainer(复制war) + Volumes(共享war) + Tomcat(使用war)

InitContainer 在其他容器启动之前启动

### Deployment

- 维护pod 数量
- Pod 的更新升级
- ReplicaSet

## Job CronJob 

## Daemon Set

## ConfigMap

- Secret
- ServiceAccount
- Ressource
- Qos
- SecuityContext
- InitContainer

### Sidecar

容器的设计模式

场景：

- 应用日志收集
- 代理容器
- 适配器容器

设计模式的本质：解耦和重用

## kubernets 资源

- label
- annotations
- OwnerReference

- Spec
- Status
- Metadata
  - Labels
  - Annotations
  - OwnerReference

## kubernets 控制运行

status -> spec

![k8s-controller.png](./images/k8s-controller.png)

## Links

- [https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [https://kubernetes.io/docs/concepts/architecture](https://kubernetes.io/docs/concepts/architecture)
- [kubernetes.md](kubernetes.md)