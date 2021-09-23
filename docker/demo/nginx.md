# nginx

```config
server {
    listen       8086;
    listen       [::]:8086;

    location / {
         index index.html;
         alias /root/wwww/web001/;
    }

    location  /api/ {
	     proxy_pass       http://localhost:8087/;
	     proxy_set_header Host      $host;
	     proxy_set_header X-Real-IP $remote_addr;
	}


}
```
