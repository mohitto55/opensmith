---
name: deploy
description: "{{PROJECT_NAME}} 프론트엔드/백엔드를 Kubernetes에 배포. '배포해줘', 'deploy', '프로덕션 반영' 등을 요청할 때 사용."
disable-model-invocation: true
allowed-tools: Bash(docker *), Bash(kubectl *), Bash({{CLOUD_CLI}} *), Bash(git *)
argument-hint: "[frontend|backend|all]"
---

# {{PROJECT_NAME}} 배포

{{PROJECT_NAME}} 프론트엔드 및 백엔드를 Kubernetes 클러스터에 배포합니다.

## 인프라 정보

# Customize: Fill in your infrastructure details
- **리전**: {{CLOUD_REGION}}
- **컨테이너 레지스트리**: {{CONTAINER_REGISTRY}}
- **레지스트리 네임스페이스**: {{REGISTRY_NAMESPACE}}
- **K8s 네임스페이스**: {{K8S_NAMESPACE}}
- **이미지 시크릿**: {{IMAGE_PULL_SECRET}}

### 이미지 경로

| 서비스 | 이미지 |
|--------|--------|
| Frontend | `{{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/frontend:<tag>` |
| Backend | `{{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/backend:<tag>` |

## 배포 대상 결정

`$ARGUMENTS`를 확인하여 배포 대상을 결정합니다:
- `frontend` → 프론트엔드만 배포
- `backend` → 백엔드만 배포
- `all` 또는 인수 없음 → 전체 배포

## 배포 워크플로우

### 0단계: 사전 확인

배포 전 반드시 확인:

```bash
# 클러스터 접속 확인
kubectl get nodes

# 현재 배포 상태 확인
kubectl get pods -n {{K8S_NAMESPACE}}
kubectl get deployment -n {{K8S_NAMESPACE}}
```

현재 상태가 정상이 아니면 배포를 중단하고 사용자에게 알립니다.

### 1단계: 이미지 태그 생성

git 커밋 해시 + 날짜를 조합하여 태그를 생성합니다:

```bash
TAG=$(date +%Y%m%d)-$(git rev-parse --short HEAD)
echo "Image tag: $TAG"
```

### 2단계: Docker 이미지 빌드

#### 백엔드 빌드

```bash
docker build -t {{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/backend:$TAG -f backend/Dockerfile backend/
```

#### 프론트엔드 빌드

```bash
docker build -t {{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/frontend:$TAG -f frontend/Dockerfile frontend/
```

### 3단계: 레지스트리에 이미지 푸시

```bash
# 레지스트리 로그인
# Customize: Your container registry login command
docker login {{CONTAINER_REGISTRY}}

# 이미지 푸시
docker push {{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/backend:$TAG
docker push {{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/frontend:$TAG
```

### 4단계: K8s 배포 업데이트

```bash
# 백엔드 이미지 업데이트
kubectl set image deployment/backend backend={{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/backend:$TAG -n {{K8S_NAMESPACE}}

# 프론트엔드 이미지 업데이트
kubectl set image deployment/frontend frontend={{CONTAINER_REGISTRY}}/{{REGISTRY_NAMESPACE}}/{{PROJECT_NAME}}/frontend:$TAG -n {{K8S_NAMESPACE}}
```

### 5단계: 롤아웃 확인

```bash
# 롤아웃 상태 확인
kubectl rollout status deployment/backend -n {{K8S_NAMESPACE}} --timeout=120s
kubectl rollout status deployment/frontend -n {{K8S_NAMESPACE}} --timeout=120s

# Pod 상태 확인
kubectl get pods -n {{K8S_NAMESPACE}}
```

### 6단계: 배포 검증

```bash
# 헬스체크 확인 (Ingress IP 확인 후)
INGRESS_IP=$(kubectl get ingress {{PROJECT_NAME}}-ingress -n {{K8S_NAMESPACE}} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" --connect-timeout 5 http://$INGRESS_IP/
curl -s -o /dev/null -w "Backend:  HTTP %{http_code}\n" --connect-timeout 5 http://$INGRESS_IP/health
```

### 7단계: 결과 보고

배포 결과를 아래 형식으로 정리:

| 항목 | 결과 |
|------|------|
| 이미지 태그 | `$TAG` |
| 백엔드 배포 | 성공/실패 |
| 프론트엔드 배포 | 성공/실패 |
| 헬스체크 | HTTP 상태코드 |

## 롤백

배포 실패 시 즉시 롤백:

```bash
kubectl rollout undo deployment/backend -n {{K8S_NAMESPACE}}
kubectl rollout undo deployment/frontend -n {{K8S_NAMESPACE}}
```

## 주의사항

- 배포 전 반드시 사용자에게 배포 대상과 태그를 확인받을 것
- Docker 빌드 실패 시 푸시/배포 단계로 넘어가지 않을 것
- 롤아웃 실패 시 자동으로 롤백하고 사용자에게 알릴 것
- 레지스트리 비밀번호는 절대 출력하지 않을 것
