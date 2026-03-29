# Step 7: QA 테스트

**이 스텝은 건너뛸 수 없습니다.** 사용자가 "멈추지 말고 진행"이라고 해도 QA는 반드시 실행합니다.

## 스크린샷 규칙

QA 중 스크린샷을 찍을 때 **반드시 1500px 이하로 리사이즈**하세요.
Claude Code의 이미지 dimension limit (2000px) 초과 시 세션이 멈춥니다.

**웹 (agent-browser):**
```bash
# 뷰포트를 1280x720 이하로 설정
agent-browser --session qa set viewport 1280 720
agent-browser --session qa screenshot ./qa-output/screenshots/test.png
```

**모바일 (adb):**
```bash
# 리사이즈 후 저장 (PIL 필요)
adb exec-out screencap -p | python3 -c "
import sys; from PIL import Image; import io
img = Image.open(io.BytesIO(sys.stdin.buffer.read()))
if max(img.size) > 1500: img.thumbnail((1500, 1500))
img.save(sys.argv[1])
" ./qa-output/screenshots/test.png
```

**일반 이미지 파일:**
```bash
python3 -c "
from PIL import Image; import sys
img = Image.open(sys.argv[1])
if max(img.size) > 1500: img.thumbnail((1500, 1500)); img.save(sys.argv[1])
" ./screenshot.png
```

---

## 실행 순서

### 7-1. 기능 테스트

`.execute/state.json`에서 `feature_prd_path` 읽기 → Feature PRD의 수용 기준(Section 3) 기반 테스트:

```
각 FR에 대해:
- FR-1.1: [수용 기준] → 테스트 방법 → PASS/FAIL
```

### 7-2. scaffold 위반 검사

```
- never-do.md 금지 패턴 Grep 검색
- 타입 체크 (빌드 성공했으면 OK)
```

### 7-3. 보안 15항목 강제 검사

**반드시 `secure-web-saas.md`를 Read하고 15항목 전부 실행하세요.**

```
secure-web-saas.md 의 15항목:
 1. CORS/Preflight        9. RateLimit/Bruteforce
 2. CSRF                 10. 쿠키+세션보안
 3. XSS+CSP              11. Secret관리+Rotation
 4. SSRF                 12. HTTPS/HSTS+보안헤더
 5. AuthN/AuthZ          13. AuditLog
 6. RBAC/ABAC+테넌트격리  14. 에러노출 차단
 7. 최소권한              15. 의존성 취약점
 8. Validation+SQLi
```

**15/15 PASS가 아니면 배포로 넘어갈 수 없습니다.**
**배포 명령(kubectl, docker push 등) 실행 시 security-report-gate.sh 훅이 리포트를 확인합니다.**
**리포트가 없거나 FAIL이 있으면 배포 명령 자체가 차단됩니다 (exit 2).**

FAIL 항목 발견 시:
1. 즉시 코드 수정
2. 수정 후 해당 항목만 재검사
3. 전부 PASS할 때까지 반복
4. 3단계 에스컬레이션 적용 (1~2회 소프트 → 3~5회 에이전트 → 6회+ 강제 차단)

### 15/15 PASS 시 — 보안 리포트 파일 생성 (필수)

모든 항목이 PASS되면 **반드시** `.execute/security-report.json`을 생성하세요.
이 파일이 없으면 배포 훅이 배포를 차단합니다.

```json
{
  "timestamp": "YYYY-MM-DDTHH:MM:SS",
  "feature_name": "[feature_name]",
  "total": 15,
  "passed": 15,
  "items": [
    {"id": 1, "name": "CORS/Preflight", "result": "PASS", "detail": "..."},
    {"id": 2, "name": "CSRF", "result": "PASS", "detail": "..."},
    {"id": 3, "name": "XSS+CSP", "result": "PASS", "detail": "..."},
    ...
    {"id": 15, "name": "의존성 취약점", "result": "PASS", "detail": "..."}
  ]
}
```

### 7-4. 브라우저 테스트 (선택)

배포 후 실제 브라우저로 테스트가 필요한 경우:

```
Skill(skill="qa-test")
```

### 7-5. 알림

```bash
# QA 결과 알림
bash ${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh --event qa_pass --message "QA 통과: [feature_name] (보안 15/15 PASS)"
# 또는
bash ${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh --event qa_fail --message "QA 실패: [feature_name] ([실패 항목])"
```

### 7-6. 버그 수집

QA 중 발견된 모든 버그를 `.opensmith/bugs.json`에 기록합니다.
**bugs.json이 없으면 자동 생성합니다.**

```json
{
  "project": "[프로젝트명]",
  "bugs": [
    {
      "id": "BUG-001",
      "description": "뒤로가기 버튼이 잠금 화면을 우회함",
      "severity": "high",
      "status": "open",
      "found_at": "YYYY-MM-DDTHH:MM:SS",
      "found_by": "qa-step7",
      "feature": "[feature_name]",
      "file": "[관련 파일]",
      "resolved_at": null
    }
  ]
}
```

### 7-7. 버그 발견 시 — 즉시 수정 시도

```
버그 발견
  ↓
즉시 수정 가능?
  ├─ 가능 → 수정 → bugs.json 상태를 "fixed"로
  └─ 불가능 → bugs.json에 "open"으로 기록
  ↓
남은 버그 확인
  ├─ open 버그 0개 → step8로 진행
  └─ open 버그 있음 → 아래 진행
```

### 7-8. 미해결 버그가 있을 때

**open 버그가 남아있으면 배포로 넘어갈 수 없습니다.**

사용자에게 보고:
```
QA 결과: N개 버그 중 M개 해결, K개 미해결

미해결 버그:
- BUG-001: [설명] (severity: high)
- BUG-003: [설명] (severity: medium)

미해결 버그를 해결하기 위해 파이프라인을 처음부터 다시 실행합니다.
```

**state.json에 pending_bugs를 기록하고, /opensmith:execute를 다시 호출합니다:**

```json
{
  "current_step": 0,
  "feature_name": "[같은 기능]",
  "feature_args": "[같은 기능] — 미해결 버그 수정: BUG-001, BUG-003",
  "pending_bugs": ["BUG-001", "BUG-003"],
  "step_results": {}
}
```

→ **Skill(skill="execute", args="--resume") 를 호출하세요.**
→ 직접 step 파일을 Read하지 말고, 반드시 /opensmith:execute 스킬을 통해 재실행합니다.

재실행 후 step7에서 다시 검사할 때, bugs.json의 pending 버그가 전부 "fixed"인지 확인합니다.

### 7-9. 전부 해결 시

```
기능 테스트: PASS
보안 15항목: 15/15 PASS
미해결 버그: 0개
```

state.json: `current_step = 8`

## 필수: 다음 스텝 실행

QA 완료 (기능 PASS + 보안 15/15 PASS + 미해결 버그 0개) 후 **반드시** `execute/steps/step8-deploy.md`를 Read하고 배포 단계를 실행하세요.
