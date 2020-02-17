# telent

```sh
mkdir ~/Software
cd ~/Software
curl https://ftp.gnu.org/gnu/inetutils/inetutils-1.9.4.tar.xz -O
tar -zxvf inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
./configure --prefix=/usr/local --disable-servers --disable-hostname \
--disable-ping --disable-ping6 --disable-logger --disable-talk \
--disable-tftp --disable-whois --disable-ifconfig --disable-traceroute
make -j8
sudo make install
```
