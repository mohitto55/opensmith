# Step 7: QA 테스트

## 실행

1. `.execute/state.json`에서 `feature_prd_path` 읽기
2. Feature PRD의 수용 기준(Section 3)을 테스트 체크리스트로 변환

```
각 FR에 대해:
- FR-1.1: [수용 기준] → 테스트 방법 → PASS/FAIL
```

3. /qa-test 호출 (브라우저 테스트가 필요한 경우):

```
Skill(skill="qa-test")
```

4. 이슈 발견 시 → 코드 수정 → `execute/steps/step6-build.md`로 되돌림

완료 후 state.json: `current_step = 8`

다음 스텝: `execute/steps/step8-deploy.md`
