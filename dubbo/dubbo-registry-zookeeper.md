# zookeeper

## uml

![ZookeeperRegistry](images/dubbo-registry-zookeeper.png)

## zookeeper info

```sh
# 在
ls /dubbo

[cn.web1992.dubbo.demo.DemoService]

ls /dubbo/cn.web1992.dubbo.demo.DemoService

[configurators, consumers, providers, routers]

```

```sh

# 在 consumer 启动后的信息
ls /dubbo/cn.web1992.dubbo.demo.DemoService/consumers

# output

# [consumer%3A%2F%2F10.108.3.7%2Fcn.web1992.dubbo.demo.DemoService%3Fapplication%3
# Ddemo-consumer%26category%3Dconsumers%26check%3Dfalse%26default.lazy%3Dfalse%26d
# efault.sticky%3Dfalse%26dubbo%3D2.0.2%26interface%3Dcn.web1992.dubbo.demo.DemoSe
# rvice%26lazy%3Dfalse%26methods%3DsayHello%2Cdemo%26pid%3D27220%26qos.port%3D3333
# 3%26release%3D2.7.1%26retries%3D0%26side%3Dconsumer%26sticky%3Dfalse%26timestamp
# %3D1555490957945]

# 解码之后的数据

# [consumer://10.108.3.7/cn.web1992.dubbo.demo.DemoService?application%3
# Ddemo-consumer&category=consumers&check=false&default.lazy=false&d
# efault.sticky=false&dubbo=2.0.2&interface=cn.web1992.dubbo.demo.DemoSe
# rvice&lazy=false&methods=sayHello,demo&pid=27220&qos.port=3333
# 3&release=2.7.1&retries=0&side=consumer&sticky=false&timestamp
# =1555490957945]

## 在 consumer 关闭之后，执行

ls /dubbo/cn.web1992.dubbo.demo.DemoService/consumers

# output

#[]

```