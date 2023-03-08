# Docker Develop Guide (With. Golang)

### Troubleshooting

1. WAS가 제대로 로딩이 되지 않을 때

```sh
docker exec -it roach ./cockroach sql --insecure
CREATE DATABASE mydb;
CREATE USER totoro;
GRANT ALL ON DATABASE mydb TO totoro;
```
