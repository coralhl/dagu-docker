# dagu-docker

[Dagu](https://github.com/dagu-org/dagu) docker image Alpine based.

docker-compose.yml

```yaml
services:
  dagu:
    container_name: dagu
    image: coralhl/dagu
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Moscow
    volumes:
      - /path/to/dagu/data:/app
    ports:
      - 8145:8080
```
