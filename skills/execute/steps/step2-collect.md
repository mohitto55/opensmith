# Step 2: 관련 자료 수집 (4-소스 병렬)

핵심 차별화 스텝. Memory Bank + 코드베이스 + 문서 + GitHub를 병렬 검색합니다.

## 소스 A: Memory Bank 시맨틱 검색

```bash
# $FEATURE_ARGS는 현재 기능 설명 (step0에서 파악한 것)
.claude/hooks/lib/memory-query.sh "$FEATURE_ARGS" --top-k 5 --type decision
.claude/hooks/lib/memory-query.sh "$FEATURE_ARGS 에러" --top-k 3 --type error
.claude/hooks/lib/memory-query.sh "$FEATURE_ARGS" --top-k 3 --type constraint
.claude/hooks/lib/memory-query.sh "$FEATURE_ARGS" --top-k 3 --type pattern
```

Memory Bank가 없거나 비어있으면 → 경고 출력 후 스킵

### 활용 매핑
| 팩트 타입 | 반영처 |
|-----------|--------|
| decision | Step 3 설계에 과거 결정 반영 |
| error | Step 3 주의사항에 포함 |
| constraint | Step 3 제약사항으로 추가 |
| pattern | Step 5 구현 시 참고 패턴으로 전달 |

## 소스 B: 코드베이스 탐색

```
Agent(subagent_type="Explore", prompt="
다음 기능과 관련된 코드를 찾아주세요: $FEATURE_ARGS

찾아야 할 것:
1. 관련 API 엔드포인트
2. 관련 서비스
3. 관련 데이터 모델
4. 관련 프론트엔드 컴포넌트
5. 관련 타입/인터페이스
6. 유사 기능 구현 패턴
")
```

## 소스 C: 문서 검색

```
- docs/architecture.md
- docs/design/ 기존 설계 문서
- .claude/skills/frontend-patterns.md
- .claude/skills/backend-patterns.md
- .claude/skills/never-do.md
```

## 소스 D: GitHub 컨텍스트

`.opensmith/config.json`에서 GitHub 레포 정보를 읽고 관련 PR/이슈를 검색합니다.

```bash
# 관련 PR 검색 (머지된 것 포함)
gh pr list --search "$FEATURE_ARGS" --state all --limit 10 --json title,body,url,state,reviews

# 관련 이슈 검색
gh issue list --search "$FEATURE_ARGS" --state all --limit 10 --json title,body,url,labels

# 최근 머지된 PR의 리뷰 코멘트 (관련 PR이 있을 때)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --jq '.[].body'

# 현재 열린 PR 확인 (충돌 가능성 파악)
gh pr list --state open --json title,headRefName,baseRefName
```

GitHub CLI(`gh`)가 없거나 인증 안 되어 있으면 → 경고 출력 후 스킵

### 활용 매핑
| GitHub 소스 | 반영처 |
|-------------|--------|
| 과거 PR 리뷰 코멘트 | Step 3 설계 주의사항 (리뷰어 피드백 반영) |
| 관련 이슈 | Step 1 세분화 PRD 보강 (요구사항 디테일) |
| 열린 PR | Step 5 구현 시 충돌 방지 |

## 결과 통합

수집 결과를 `docs/prd/features/[기능명]/context.md`에 저장:

```markdown
# 수집 컨텍스트: [기능명]

## Memory Bank
### 과거 의사결정
- ...
### 에러 패턴
- ...
### 제약사항
- ...
### 참고 패턴
- ...

## 코드베이스
### 관련 파일
- ...
### 재사용 가능 코드
- ...

## 문서
### 아키텍처 요약
- ...
### Scaffold 규칙
- ...

## GitHub
### 관련 PR
- ...
### 관련 이슈
- ...
### 리뷰 코멘트
- ...
```

다음 스텝 실행: `execute/steps/step3-design.md` 를 Read하고 따르세요.
