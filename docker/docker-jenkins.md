# jenkins

- [https://github.com/jenkinsci/docker](https://github.com/jenkinsci/docker)

```sh
# 下载镜像
docker pull jenkins

# 启动
docker run -d -v /Users/zl/Documents/dev/dockers/jenkins/jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
```
