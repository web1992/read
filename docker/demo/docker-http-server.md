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
