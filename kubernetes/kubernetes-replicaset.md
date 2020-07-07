# replicaset

副本控制器

## replicaset 与 Deployment 的区别

知道 Pod 的部署进度

```sh
# kubectl get deployment

NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
cardapp-deployment   2/2     2            2           10d
demo-deployment      2/2     2            2           11d
nginx-deployment     1/1     1            1           11d
spring-boots         2/2     2            2           2d

# kubectl get rs

NAME                            DESIRED   CURRENT   READY   AGE
cardapp-deployment-757c99d9f5   2         2         2       10d
demo-deployment-6bc448999b      2         2         2       11d
nginx-deployment-6b474476c4     1         1         1       11d
spring-boots-5bfd4f665c         2         2         2       2d

```
