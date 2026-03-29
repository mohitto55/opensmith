# Step 7: QA 테스트

**이 스텝은 건너뛸 수 없습니다.** 사용자가 "멈추지 말고 진행"이라고 해도 QA는 반드시 실행합니다.

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

FAIL 항목 발견 시:
1. 즉시 코드 수정
2. 수정 후 해당 항목만 재검사
3. 전부 PASS할 때까지 반복
4. 3단계 에스컬레이션 적용 (1~2회 소프트 → 3~5회 에이전트 → 6회+ 강제 차단)

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

### 7-6. 이슈 발견 시

```
기능 이슈 → 코드 수정 → execute/steps/step6-build.md 로 되돌림
보안 이슈 → 즉시 수정 → 해당 보안 항목만 재검사
```

state.json: `current_step = 8`

## 필수: 다음 스텝 실행

QA 완료 (기능 PASS + 보안 15/15 PASS) 후 **반드시** `execute/steps/step8-deploy.md`를 Read하고 배포 단계를 실행하세요.
