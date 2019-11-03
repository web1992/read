# docker install

- [https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-centos-7](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-centos-7)

## install docker on centos

```sh
sudo yum check-update

curl -fsSL https://get.docker.com/ | sh

sudo systemctl start docker

sudo systemctl status docker

# Lastly, make sure it starts at every server reboot:
sudo systemctl enable docker

```
