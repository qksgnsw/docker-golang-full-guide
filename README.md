# Docker Develop Guide (With. Golang)

## CI/CD

### 순서

1. 웹서버 코드 작성
2. 도커 파일 작성
3. 도커 컴포즈 작성
4. 깃 초기화 및 푸시
5. GitHub Actions Setting
6. git pull
7. Webhook setting
8. Github Webhooks Setting
9. Zero-downtime Deploy Setting

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
>
> - git허브 브라우저에서 설정 했을 경우 반드시 pull을 받아야 함.

### Webhook Setting

1. 배포할 서버에 webhook 설치

```sh
apt install webhook
```

2. touch /path/hooks.json
3. 아래 내용 입력

```javascript
[
  {
    "id": "redeploy",
    "execute-command": "/path/zero-downtime-deploy.sh",
    "command-working-directory": "/path/docker-golang-full-guide",
    "response-message": "Redeploying API server."
  },
  {
    "id": "ping",
    "response-message": "Ping"
  }
]
```
4. 웹훅 서버 가동
```sh
webhook -hooks /path/hooks.json -verbose
```

### Github Webhooks Setting

1. Let me select individual events.
2. Workflow runs 체크

### Zero-downtime Deploy Setting

1. 서비스네임과 복제본에 대한 수량은 맞춰줘야함.

```sh
# zero-downtime-deploy.sh
##### options
service_name=web
replicas=3
##### options
```

```yml
# docker-compose.yml
services:
  web:
    <<: *default-app
    deploy:
      mode: replicated
      replicas: 3
```

### Troubleshooting

1. WAS가 제대로 로딩이 되지 않을 때

```sh
docker exec -it roach ./cockroach sql --insecure
CREATE DATABASE mydb;
CREATE USER totoro;
GRANT ALL ON DATABASE mydb TO totoro;
```
