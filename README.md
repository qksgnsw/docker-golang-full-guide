# Docker Develop Guide (With. Golang)

## CI/CD

### AWS CLI 설정

#### 1. aws-cli 설치 및 로그인

```sh
apt install awscli -y # ubuntu의 경우
aws configure
# Register AWS Access key.

# 레지스트리에 있는 리포지토리 목록을 표시
aws ecr describe-repositories
# 리포지토리 내에 있는 이미지 목록을 표시
aws ecr describe-images --repository-name {Your Repository Name.}
```

### github에 환경변수 적용

#### 1. 경로

github repository > setting > Actions secrets and variables > actions  

#### 2. 등록해야 할 환경변수

1. AWS_ACCESS_KEY_ID  
2. AWS_SECRET_ACCESS_KEY  
3. WEBHOOK_ACCESS_SECRET  

### 웹훅 구축하기

#### 1. script.sh 예시

```sh
REPOSITORY="REPOSITORY PATH."
IMAGE="IMAGE NAME"
CONTAINER_NAME="CONTAINER NAME"
NETWORK_NAME="NETWORK NAME"
NGINX_CONTAINER_NAME="NGINX"

printf "##### Delete Old Docker Container.\n"
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker rmi -f $IMAGE

printf "##### Run New Docker Container.\n"
docker pull $REPOSITORY$IMAGE:latest
docker run -itd --name $CONTAINER_NAME --network $NETWORK_NAME $REPOSITORY$IMAGE

printf "##### Restart Nginx.\n"
docker restart $NGINX_CONTAINER_NAME

printf "##### Clear Docker.\n"
echo y | docker container prune
echo y | docker image prune
```

#### 2. 웹훅 설치 및 환경 구성

```sh
# Install webhook.
apt install webhook -y
# Create webhook config
mkdir -p /path/of/hooks/config.json
```

#### 3. 웹훅 설정 파일 예시

```json
// webhook.config.json
[
  {
    "id": "{Your Route.}", 
    "execute-command": "/{Path of Your script.}/script.sh",
    "command-working-directory": "/{Path of Your Directory.}",
    "response-message": "{Response Message.}",
    "trigger-rule":
    {
      "match":
      {
        "type": "value",
        "value": "{Your token value.}", // secret key was register github secret.
        "parameter":
        {
          "source": "payload",
          "name": "{Your key.}" // Custom Key
        }
      }
    }
  }
]
```

#### 4. 서비스 파일 생성(EC2의 경우)

```sh
# Create systemd webhook.service 
vim /lib/systemd/system/webhook.service 
```

#### 5. 아래 내용 입력

```text
[Unit]
Description=Small server for creating HTTP endpoints (hooks)
Documentation=https://github.com/adnanh/webhook/

[Service]
ExecStart=/usr/bin/webhook -nopanic -hooks /path/of/hooks/config.json -verbose

[Install]
WantedBy=multi-user.target
```

#### 6. 아래 커맨드 실행

```sh
systemctl start webhook.service
systemctl enable webhook.service
```

### Github Action 세팅

#### 1. 폴더 및 파일 생성

```sh
# Make workflows Directory
mkdir -p ./.github/workflows

# Create workflows job file
touch ./.github/workflows/main.yml
```

#### 2. 아래 내용 적용

```yml
name: Dockerizing to Amazon ECR

on:
  push:
    branches:
      - "main"

env:
  AWS_REGION: ap-northeast-2

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: YOUR_REPOSITORY_NAME_FROM_ECR # ecr repository name
          IMAGE_TAG: ${{ github.sha }}
        run: |
          # Build a docker container and
          # push it to ECR so that it can
          # be deployed to ECS.
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker image tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
          echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

      - name: "Call Webhook"
        uses: indiesdev/curl@v1.1
        with:
          url: {YOUR WEBHOOK URL/hooks/Your Route}
          method: "POST"
          headers: '{ "Content-Type": "application/json" }'
          body: '{ "Your key": "${{ secrets.WEBHOOK_ACCESS_SECRET }}" }'
```
