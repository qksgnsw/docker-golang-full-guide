# Docker Develop Guide (With. Golang)

## CI/CD

### GitHub Actions Setting

0. 아래의 명령으로 파일을 만들고 6.내용 넣어도 됨.

```sh
mkdir -p ./.github/workflows
touch ./.github/workflows/main.yml
```

1. Settings탭 > Secrets and variables > Actions 이동
2. New Repository secret 
3. DOCKERHUB_USERNAME 생성
4. DOCKERHUB_TOKEN 생성 (docker hub > Account Settings > Security)
5. Actions탭 > set up a workflow yourself 
6. 이하 내용 삽입(clockbox 부분은 이미지 네임 변경해야함)

```yml
# ./.github/workflows/main.yml
name: ci

on:
  push:
    branches:
      - "main"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      -
        name: Checkout
        uses: actions/checkout@v3
      -
        name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      -
        name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      -
        name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/docker-golang-guide:${{ github.sha }}, ${{ secrets.DOCKERHUB_USERNAME }}/docker-golang-guide:latest
```

1. Start Commit
2. main으로 푸시 할때마다 이미지 빌드 및 이미지 푸시

> 주의할 점
> - git허브 브라우저에서 설정 했을 경우 반드시 pull을 받아야 함.

### Zero-downtime Deploy Setting

1. 서비스에 종속되어 있는 이름을 shell scrypt 인자로 사용
```yml
# docker-compose.yml
services:
  web:
```
```sh
# zero-downtime-deploy.sh
service_name=$1
```
2. 예
```sh
./zero-downtime-deploy web
```

### Troubleshooting

1. WAS가 제대로 로딩이 되지 않을 때

```sh
docker exec -it roach ./cockroach sql --insecure
CREATE DATABASE mydb;
CREATE USER totoro;
GRANT ALL ON DATABASE mydb TO totoro;
```
