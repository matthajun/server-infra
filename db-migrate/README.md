# db-migrate

## 1. 소개

서버 배포 시, 서버 deployment yaml 의 `initContainers`에서 이미지를 통해 liquibase 를 사용하여 database 마이그레이션과 
AWS Secrets Manager 의 환경변수를 컨테이너 내에 저장합니다.

## 2. 빌드 방법

```
$ docker build -t db-migrate . --platform linux/amd64
$ docker tag db-migrate [AWS-ECR-HOST]/db-migrate:latest
$ docker push [AWS-ECR-HOST]/db-migrate:latest
```

- Amazon ECR 에 image push 할 때, aws ecr login 이 먼저 선행되어야 함

## 3. 확인 필요

배포하려는 환경과 네임스페이스에 `aws-gateway-key` 라는 Config Map 이 있어야 하며 다음의 내용이 있어야 함

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
X_API_KEY
```
