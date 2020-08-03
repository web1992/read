# ttp-server

```Dockerfile
FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get update
RUN apt-get install -y nodejs
RUN npm install -g http-server

# Add additional tools
RUN apt-get install -y nano links git wget curl htop

RUN mkdir -p /var/www/

COPY agent.zip /var/www/

WORKDIR /var/www/

CMD http-server .
```

build.sh

```sh
#!/usr/bin/env bash
#imagesid=`docker images |awk -F" " 'NR==2 {print $3}'`
imagesid=`date +%s`
repo="cardapp"
echo ${imagesid}

docker build -t registry.cn-hangzhou.aliyuncs.com/web1992/cardapp:${imagesid} .

docker push registry.cn-hangzhou.aliyuncs.com/web1992/cardapp:${imagesid}

sed  s/versionxxxx/${imagesid}/g temp-deployment.yml > ${repo}-deployment.yml

#sed  s/repoxxxxx/${repo}/g temp-deployment.yml

kubectl apply -f ${repo}-deployment.yml
```

`temp-deployment.yml`

```yaml
apiVersion: apps/v1 # v1 for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: cardapp-deployment
spec:
  selector:
    matchLabels:
      app: cardapp
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: cardapp
    spec:
      containers:
      - name: cardapp
        image: registry.cn-hangzhou.aliyuncs.com/web1992/cardapp:versionxxxx
        ports:
        - containerPort: 80
```
