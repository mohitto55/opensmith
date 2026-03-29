# Step 9: 완료 보고

`shared/report.md`를 Read하고 그 지시를 따르세요.

## 완료 후: --all 모드 루프 체크

report 실행 후 **반드시** 아래 루프 체크를 수행하세요.

### 1. state.json의 mode 확인

```
mode가 "all"인가?
  ├─ 아니다 (single) → current_step = "done", 파이프라인 종료
  └─ 맞다 (all) → 아래 진행
```

### 2. 현재 기능을 completed_features에 추가

```json
state.json 업데이트:
- completed_features에 현재 feature_name 추가
- feature_queue에서 현재 feature_name 제거
```

### 3. 다음 미구현 기능 확인

```
feature_queue에 남은 기능이 있는가?
  ├─ 있다 → 다음 기능으로 state.json 초기화:
  │   - feature_name = queue의 첫 번째 기능
  │   - feature_args = 해당 기능 설명
  │   - current_step = 0
  │   - feature_prd_path = null
  │   - design_path = null
  │   - memory_bank_context = null
  │   - step_results = {}
  │   → execute/steps/step0-read-prd.md 를 Read하고 실행
  │
  └─ 없다 → 전체 완료 보고:
      - current_step = "done"
      - 전체 구현 요약 출력:
        "전체 기능 구현 완료!
         완료된 기능: [completed_features 목록]
         총 N개 기능 구현 + QA + 배포"
```

### 4. 다음 기능 시작 전 안내

```
[기능명] 구현 완료. 다음 기능: [다음 기능명]
자동으로 진행합니다.
```

**반드시 step0부터 다시 시작하세요. 이전 기능의 컨텍스트를 재사용하지 마세요.**
