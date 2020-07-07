# Service

外部访问和负载均衡

## 声明

Headless Service ClusterIP None -> service name(DNS)

Node Port

LoadBalacne

## 底层

- Cloud Controller Manager
- Coredns
- iptables
- IPVS

## 常用命令

```sh
# kubectl get endpoints

NAME                   ENDPOINTS                       AGE
cardapp-service        10.0.4.2:80,10.0.9.3:80         10d
demo-service           10.0.10.3:80,10.0.15.2:80       11d
kubernetes             172.17.0.11:6443                12d
nginx-service          10.0.10.2:80                    11d
spring-boots-service   10.0.10.5:8080,10.0.15.4:8080   47h
springboots-service    10.0.10.5:8080,10.0.15.4:8080   47h

# kubectl get svc
# kubectl get service

NAME                   TYPE        CLUSTER-IP        EXTERNAL-IP   PORT(S)         AGE
cardapp-service        NodePort    169.169.109.146   <none>        8084:8084/TCP   10d
demo-service           NodePort    169.169.244.160   <none>        8081:8081/TCP   11d
kubernetes             ClusterIP   169.169.0.1       <none>        443/TCP         12d
nginx-service          NodePort    169.169.207.141   <none>        8082:8082/TCP   11d
spring-boots-service   NodePort    169.169.43.148    <none>        8083:8083/TCP   47h
springboots-service    NodePort    169.169.16.115    <none>        8089:8089/TCP   47h

```

```sh
# kubectl get svc spring-boots-service -o yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2020-07-05T14:40:31Z"
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        f:externalTrafficPolicy: {}
        f:ports:
          .: {}
          k:{"port":8083,"protocol":"TCP"}:
            .: {}
            f:nodePort: {}
            f:port: {}
            f:protocol: {}
            f:targetPort: {}
        f:selector:
          .: {}
          f:app: {}
        f:sessionAffinity: {}
        f:type: {}
    manager: kubectl
    operation: Update
    time: "2020-07-05T14:40:31Z"
  name: spring-boots-service
  namespace: default
  resourceVersion: "2139923"
  selfLink: /api/v1/namespaces/default/services/spring-boots-service
  uid: 4cc04c35-1a2a-42dd-bfd1-c15fa1b403e1
spec:
  clusterIP: 169.169.43.148
  externalTrafficPolicy: Cluster
  ports:
  - nodePort: 8083
    port: 8083
    protocol: TCP
    targetPort: 8080
  selector:
    app: spring-boots
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
```

## 外部访问 Service

Node IP
Pod IP
Cluster : IP Service IP
