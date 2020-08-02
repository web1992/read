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

echo ${imagesid}

docker build -t registry.cn-hangzhou.aliyuncs.com/web1992/spring-boots:${imagesid} .

docker push registry.cn-hangzhou.aliyuncs.com/web1992/spring-boots:${imagesid}

```
