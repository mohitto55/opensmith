# 서브스킬: 완료 보고

## 실행

1. **PRD 상태 갱신**
   - `docs/prd/features/[feature_name]/README.md` 상태 → `Implemented`
   - `docs/prd/system-prd.md` Section 9 기능 목록 상태 갱신

2. **Memory Bank 피드백**
   - 이번 구현에서 중요한 의사결정이 있었으면 즉시 기록
   - 나머지는 세션 종료 시 `fact-extraction.sh` 훅이 자동 처리

3. **커밋**

4. **완료 요약 출력**

```
기능 구현 완료: [feature_name]

📋 PRD: [feature_prd_path]
📐 설계: [design_path]

변경 사항:
- Backend: [파일 목록]
- Frontend: [파일 목록]
- DB: [새 모델/인덱스]

QA: [PASS/FAIL]
배포: [성공/스킵]
Memory Bank: 반영 [N개] / 신규 기록 [N개]
```

5. **알림 발송**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh --event feature_done --message "기능 구현 완료: [feature_name]\nQA: [PASS/FAIL]\n배포: [성공/스킵]"
```

6. `state.json`: `current_step = "done"`
