# Step 9: 완료 보고

`shared/report.md`를 Read하고 그 지시를 따르세요.

## 완료 후: --all 모드 루프 체크

report 실행 후 **반드시** 아래 루프 체크를 수행하세요.

### 1. --all 모드 확인

```
--all 모드인가?
  ├─ 아니다 (single) → 파이프라인 종료
  └─ 맞다 (all) → 아래 진행
```

### 2. system-prd.md의 현재 기능을 "Implemented"로 마킹

`docs/prd/system-prd.md` Section 9에서 현재 기능의 상태를 "Implemented"로 변경합니다.

### 3. 다음 미구현 기능 확인

```
Section 9에 "Implemented"가 아닌 기능이 남아있는가?
  ├─ 있다 → 다음 기능으로 전환:
  │   → execute/steps/step0-read-prd.md 를 Read하고 실행
  │
  └─ 없다 → 전체 완료 보고:
      "전체 기능 구현 완료!
       완료된 기능: [목록]
       총 N개 기능 구현 + QA + 배포"
```

### 4. 다음 기능 시작 전 안내

```
[기능명] 구현 완료. 다음 기능: [다음 기능명]
자동으로 진행합니다.
```

**반드시 step0부터 다시 시작하세요. 이전 기능의 컨텍스트를 재사용하지 마세요.**
