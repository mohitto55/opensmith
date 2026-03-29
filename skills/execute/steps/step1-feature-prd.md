# Step 1: 세분화 PRD 확인/생성

## 실행

1. `docs/prd/features/` 에서 `$ARGUMENTS` 관련 PRD 검색

```
있다 → 읽기 → 현재 요구사항과 비교
  ├─ 충분 → Step 2로
  └─ 보완 필요 → 갱신
없다 → 자동 생성
```

2. 자동 생성 시 아래 형식으로 작성

저장: `docs/prd/features/[feature-name-kebab]/README.md`

```markdown
# Feature PRD: [기능명]

> 상위 PRD: docs/prd/system-prd.md
> 작성일: YYYY-MM-DD
> 상태: Auto-generated

## 1. 개요
- 기능 요약 / 상위 사용자 스토리 참조 / 해결하는 문제

## 2. 사용자 스토리
| ID | 사용자 | 행동 | 목적 | 수용 기준 |
|----|--------|------|------|-----------|

## 3. 기능 요구사항
### P0 — 필수
| ID | 기능 | 설명 | 수용 기준 |
### P1 — 중요

## 4. UI/UX 요구사항
- 화면 구성 / 인터랙션 / 상태 (로딩, 에러, 빈 상태)

## 5. API 요구사항 (개략)
| 메서드 | 경로 | 설명 |

## 6. 데이터 요구사항 (개략)
- 새 엔티티 / 기존 변경 / 관계

## 7. 엣지 케이스

## 8. 의존성
- 기존 기능 / 외부 서비스 / 선행 작업
```

3. 사용자에게 확인 요청:

```
세분화 PRD를 생성했습니다: docs/prd/features/[기능명]/README.md
검토해주세요. 수정할 부분이 있으면 알려주세요.
```

4. 확인 후 `.execute/state.json` 업데이트:

```json
{
  "feature_name": "[kebab-case]",
  "feature_prd_path": "docs/prd/features/[기능명]/README.md",
  "current_step": 2
}
```

5. 다음 스텝 실행: `execute/steps/step2-collect.md` 를 Read하고 따르세요.
