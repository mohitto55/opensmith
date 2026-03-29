# Step 2: 관련 자료 수집 (3-소스 병렬)

핵심 차별화 스텝. Memory Bank + 코드베이스 + 문서를 병렬 검색합니다.

## 소스 A: Memory Bank 시맨틱 검색

```bash
FEATURE_ARGS=$(python3 -c "import json; print(json.load(open('.execute/state.json'))['feature_args'])")

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

## 결과 통합

수집 결과를 `.execute/state.json`에 저장:

```json
{
  "memory_bank_context": {
    "decisions": [...],
    "errors": [...],
    "constraints": [...],
    "patterns": [...]
  },
  "codebase_context": {
    "related_files": [...],
    "reusable_code": [...],
    "similar_patterns": [...]
  },
  "docs_context": {
    "architecture": "...",
    "scaffold_rules": "..."
  },
  "current_step": 3
}
```

다음 스텝 실행: `execute/steps/step3-design.md` 를 Read하고 따르세요.
