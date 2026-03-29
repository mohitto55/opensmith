# Step 7: QA 테스트

**이 스텝은 건너뛸 수 없습니다.** 사용자가 "멈추지 말고 진행"이라고 해도 QA는 반드시 실행합니다.

## 실행

1. `.execute/state.json`에서 `feature_prd_path` 읽기
2. Feature PRD의 수용 기준(Section 3)을 테스트 체크리스트로 변환

```
각 FR에 대해:
- FR-1.1: [수용 기준] → 테스트 방법 → PASS/FAIL
```

3. 코드 레벨 QA:
   - scaffold never-do 위반 검사 (Grep으로 금지 패턴 검색)
   - 보안 취약점 검사 (하드코딩 시크릿, API 키 등)
   - 타입 체크 (빌드 성공했으면 OK)

4. /qa-test 호출 (브라우저 테스트가 필요한 경우):

```
Skill(skill="qa-test")
```

5. 이슈 발견 시 → 코드 수정 → `execute/steps/step6-build.md`로 되돌림

state.json: `current_step = 8`

## 필수: 다음 스텝 실행

QA 완료 후 **반드시** `execute/steps/step8-deploy.md`를 Read하고 배포 단계를 실행하세요.
