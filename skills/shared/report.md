# 서브스킬: 완료 보고

## 실행

1. **PRD 상태 갱신**
   - `docs/prd/features/[feature_name]/README.md` 상태 → `Implemented`
   - `docs/prd/system-prd.md` Section 9 기능 목록 상태 갱신

2. **Memory Bank 팩트 자동 추출**

   이번 구현에서 배운 것을 facts로 추출하여 저장합니다.
   아래 카테고리별로 해당 사항이 있으면 JSON 배열을 만들어 실행하세요:

   ```
   카테고리:
   - decision: 기술/아키텍처 선택과 그 이유
   - pattern: 발견한 코딩 패턴/컨벤션
   - error: 만난 에러와 해결 방법
   - constraint: 발견한 프로젝트 제약사항
   - self-improve: scaffold/파이프라인 개선이 필요한 패턴
   ```

   ```bash
   python scripts/extract-facts.py --save-json '[
     {"type":"decision","fact":"설명","confidence":0.8,"tags":["태그"]},
     {"type":"error","fact":"설명","confidence":0.7,"tags":["태그"]}
   ]'
   ```

   - confidence: 0.5~1.0 (확실할수록 높게)
   - 해당 사항 없으면 스킵
   - 임베딩은 자동 생성됨

3. **GitHub 이슈 클로즈**

배포가 완료된 경우, 이 기능과 관련된 GitHub 이슈를 자동으로 닫습니다.

```
해결된 이슈 찾기:
  1. Feature PRD(docs/prd/features/[기능명]/README.md)의 Section 9 Bugs에서
     status가 "fixed"이고 github_issue가 있는 항목 수집
  2. step0에서 동기화한 GitHub 이슈 중 이 기능과 관련된 것 확인
  3. PRD Section 10 TODOs에서 status가 "done"이고 GH- 접두어가 있는 항목 수집

각 이슈에 대해:
  gh issue close [이슈번호] --comment "Resolved in [feature_name]. Deployed successfully."

gh 명령 실패 시 → 경고만 출력하고 계속 진행
```

4. **커밋**

5. **완료 요약 출력**

```
기능 구현 완료: [feature_name]

PRD: docs/prd/features/[기능명]/README.md
설계: docs/design/[기능명].md

변경 사항:
- Backend: [파일 목록]
- Frontend: [파일 목록]
- DB: [새 모델/인덱스]

QA: [PASS/FAIL]
배포: [성공/스킵]
GitHub 이슈 클로즈: [#번호, #번호, ...] (또는 "해당 없음")
Memory Bank: 반영 [N개] / 신규 기록 [N개]
```

6. **알림 발송**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh --event feature_done --message "기능 구현 완료: [feature_name]\nQA: [PASS/FAIL]\n배포: [성공/스킵]"
```
