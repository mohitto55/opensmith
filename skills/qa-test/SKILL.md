---
name: qa-test
description: "{{PROJECT_NAME}} 웹사이트를 agent-browser로 자동 QA 테스트. 'QA 해줘', '테스트 해줘', '사이트 점검', 'dogfood', 'bug hunt' 등을 요청할 때 사용."
disable-model-invocation: true
allowed-tools: Bash(agent-browser *), Bash(agent-browser:*), Bash(npx agent-browser *), Bash(mkdir *), Bash(cat *), Bash(echo *)
---

# {{PROJECT_NAME}} QA 자동화 테스트

agent-browser 스킬을 활용하여 {{PROJECT_NAME}} 웹사이트를 체계적으로 탐색하고 버그, UX 문제를 발견합니다.

## 사전 요구사항

agent-browser가 설치되어 있어야 합니다. 없으면 먼저 설치:

```bash
npm i -g agent-browser
agent-browser install
```

## 서버 주소 확인

QA 시작 전 서버 접속 주소를 확인합니다:

```bash
kubectl get ingress -n {{K8S_NAMESPACE}}
```

Ingress의 ADDRESS 컬럼에서 외부 IP를 확인합니다. 기본 URL은 `http://<EXTERNAL-IP>/` 입니다.

## 중요: 실제 사용자 환경 시뮬레이션

agent-browser는 Chromium headless로 실행되어, 일반 사용자의 HTTP 브라우저 환경과 다르다.
**Chromium headless는 HTTP에서도 Secure Context로 동작**하기 때문에, Secure Context 전용 API(crypto.randomUUID, Notification 등)가
agent-browser에서는 정상 동작하지만 실제 사용자 브라우저에서는 에러가 발생할 수 있다.

**이 차이는 Chrome 플래그로 해결할 수 없다.** 따라서 반드시 아래 Secure Context 감사를 수행해야 한다.

### Secure Context 감사 (필수)

모든 페이지에서 다음 eval 명령으로 Secure Context 전용 API 사용 여부를 점검한다:

```bash
# isSecureContext 확인 (HTTP 사이트에서 true이면 agent-browser 환경 차이)
agent-browser --session qa eval 'window.isSecureContext'

# Secure Context 전용 API 존재 여부 확인 (복잡한 JS는 --stdin 사용)
agent-browser --session qa eval --stdin <<'EVALEOF'
JSON.stringify({
  isSecureContext: window.isSecureContext,
  cryptoRandomUUID: typeof crypto.randomUUID,
  notification: typeof Notification,
  serviceWorker: typeof navigator.serviceWorker?.register,
  credentials: typeof navigator.credentials?.create
})
EVALEOF
```

만약 `isSecureContext: true`이고 사이트가 HTTP라면, 코드에서 Secure Context 전용 API를 사용하는지 점검:

```bash
agent-browser --session qa eval 'document.documentElement.innerHTML.includes("crypto.randomUUID")'
agent-browser --session qa eval 'document.documentElement.innerHTML.includes("navigator.serviceWorker")'
```

**발견 시 반드시 이슈로 보고한다.** agent-browser에서 동작하더라도 실제 사용자 HTTP 브라우저에서는 에러가 발생하는 버그이다.

### 추가 확인 항목
- `agent-browser --session qa console` 로 JS 에러(특히 "is not a function", "is not defined") 확인
- `agent-browser --session qa errors` 로 네트워크 에러 확인
- HTTP 환경에서 동작하지 않는 기능이 있는지 체크

## QA 워크플로우 (6단계)

### 1단계: 초기화

반드시 `--headed` 모드로 실행하여 실제 브라우저 창을 띄운다.

```bash
mkdir -p ./qa-output/screenshots ./qa-output/videos
agent-browser --session qa --headed --args "--unsafely-treat-insecure-origin-as-secure=http://<EXTERNAL-IP>" --ignore-https-errors open <TARGET_URL>
agent-browser --session qa wait --load networkidle
```

### 2단계: 전체 스냅샷

```bash
# annotated 스크린샷으로 요소 번호까지 한번에 확인
agent-browser --session qa screenshot --annotate ./qa-output/screenshots/initial.png
# 인터랙티브 요소 + cursor-interactive 요소까지 포함
agent-browser --session qa snapshot -i -C
```

### 3단계: 페이지별 체계적 탐색

# Customize: List your project's key pages and test scenarios
# Example pages to test:
# - Main page: logo, navigation, core UI elements
# - List/search pages: filtering, sorting, pagination
# - Detail pages: data display, interactions
# - Form pages: input validation, submission
# - API health: /health endpoint

각 페이지에서 반드시 수행:

```bash
# 체이닝으로 한번에 스냅샷 + 스크린샷 + 에러 확인
agent-browser --session qa snapshot -i -C
agent-browser --session qa screenshot --annotate ./qa-output/screenshots/{page-name}.png
agent-browser --session qa errors
agent-browser --session qa console
```

#### 반응형 테스트 (모바일)

```bash
agent-browser --session qa set viewport 375 812
agent-browser --session qa screenshot --annotate ./qa-output/screenshots/mobile-main.png
agent-browser --session qa snapshot -i
# 테스트 후 데스크톱으로 복원
agent-browser --session qa set viewport 1280 720
```

### 4단계: 문제 발견 시 증거 수집

#### 상호작용 버그 (비디오 + 스크린샷 + diff)

```bash
# 기준 스냅샷 저장
agent-browser --session qa snapshot -i
agent-browser --session qa record start ./qa-output/videos/issue-{NNN}-repro.webm
agent-browser --session qa screenshot ./qa-output/screenshots/issue-{NNN}-step-1.png
sleep 1
# 재현 동작 수행 (type 사용 - 사람처럼 문자 단위 입력)
sleep 1
agent-browser --session qa screenshot ./qa-output/screenshots/issue-{NNN}-step-2.png
sleep 2
agent-browser --session qa screenshot --annotate ./qa-output/screenshots/issue-{NNN}-result.png
# diff로 변경사항 확인
agent-browser --session qa diff snapshot
agent-browser --session qa record stop
```

#### 정적 버그 (스크린샷만)

```bash
agent-browser --session qa screenshot --annotate ./qa-output/screenshots/issue-{NNN}.png
```

### 5단계: 보고서 작성

발견된 문제를 [보고서 템플릿](templates/qa-report-template.md)에 따라 `./qa-output/report.md`에 작성합니다.

문제를 발견할 때마다 즉시 보고서에 추가합니다 (마지막에 몰아쓰지 않음).

### 6단계: 이슈 수정 및 재테스트 (반복)

이슈가 발견되면 **수정 → 배포 → 재테스트**를 이슈가 0건이 될 때까지 반복한다.

#### 반복 프로세스

1. **이슈 분석**: 보고서에 기록된 이슈의 원인을 소스코드에서 파악
2. **코드 수정**: 프론트엔드(`frontend/`) 또는 백엔드(`backend/`) 코드 수정
3. **배포**: 수정된 코드를 서버에 반영
   # Customize: Your deployment process
   ```bash
   kubectl rollout restart deployment/frontend -n {{K8S_NAMESPACE}}
   kubectl rollout status deployment/frontend -n {{K8S_NAMESPACE}} --timeout=180s
   curl -s -o /dev/null -w "HTTP %{http_code}" --connect-timeout 5 http://<EXTERNAL-IP>/
   ```
4. **재테스트**: `--headed` 모드로 agent-browser를 다시 열어서 수정된 이슈가 해결됐는지 확인
5. **보고서 업데이트**: 해결된 이슈는 상태를 `Fixed`로 변경, 새로 발견된 이슈 추가
6. **반복 판단**:
   - 미해결 이슈가 남아있으면 → 1번으로 돌아감
   - 모든 이슈가 해결되었으면 → 7단계(마무리)로 진행

#### 반복 중 주의사항

- 한 번에 하나의 이슈만 수정하고 재테스트 (여러 이슈를 한번에 수정하면 원인 추적이 어려움)
- 수정 후 반드시 해당 이슈뿐 아니라 **전체 페이지를 다시 테스트** (회귀 버그 방지)
- 수정이 불가능한 이슈(이미지 에셋 누락 등)는 `Won't Fix` / `Deferred`로 분류하고 사용자에게 보고
- 3회 이상 같은 이슈가 재발하면 근본 원인 분석 후 사용자에게 에스컬레이션

### 7단계: 마무리

모든 이슈가 해결(또는 분류)된 후 최종 마무리:

```bash
agent-browser --session qa close
```

최종 보고서에 다음을 포함:
- 총 발견 이슈 수 / 해결된 이슈 수 / 미해결 이슈 수
- 각 이슈별 상태 (Fixed / Won't Fix / Deferred)
- 반복 테스트 횟수

## 핵심 원칙

- **Secure Context 감사 필수**: agent-browser(Chromium headless)는 HTTP에서도 Secure Context로 동작한다. 따라서 모든 페이지에서 eval로 `isSecureContext`, `crypto.randomUUID` 등을 확인하고, 코드에서 Secure Context 전용 API를 사용하는지 반드시 점검해야 한다. 이 차이는 Chrome 플래그로 해결 불가능하다
- **재현이 핵심**: 모든 문제는 증거(스크린샷/비디오)가 반드시 있어야 함
- **사용자처럼 테스트**: 실제 사용자가 할 법한 행동으로 탐색
- **콘솔 확인**: JS 에러, 네트워크 실패 등 UI에 안 보이는 문제 탐지. 특히 "is not a function", "is not defined" 에러는 환경 차이 버그일 수 있음
- **깊이 > 수량**: 5개의 완벽한 재현 증거가 20개의 모호한 보고보다 낫다
- **snapshot -i -C**: 클릭/입력 가능 요소 + cursor-interactive 요소까지 찾을 때 사용
- **snapshot** (플래그 없음): 페이지 콘텐츠 읽을 때 사용
- **diff snapshot**: 액션 후 변경사항을 확인할 때 사용 (기준 스냅샷 대비)
- **--annotate**: 스크린샷에 요소 번호 오버레이. ref 없이 바로 인터랙션 가능
- **eval --stdin**: 복잡한 JS 실행 시 셸 이스케이프 문제 방지
- **비디오 녹화 중 type 사용**: fill 대신 type으로 문자 단위 입력 (사람처럼)
- **동작 사이 sleep**: 비디오에서 1배속 시청 가능하도록
