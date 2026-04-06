#!/bin/bash
# 팩트 추출 훅 (Stop 이벤트)
# Claude Code 세션 종료 시 실행
#
# 이 훅은 Claude Code에게 fact 추출을 지시하는 메시지를 출력합니다.
# Claude Code가 직접 대화 컨텍스트에서 fact를 판단하고 저장합니다.
# (외부 API 호출 불필요)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
MEMORY_DB="$PROJECT_ROOT/.opensmith/memory-bank/memory.db"

# Memory Bank가 없으면 스킵
if [ ! -f "$MEMORY_DB" ]; then
  exit 0
fi

cat <<'PROMPT'
## 세션 종료 전 Memory Bank 팩트 추출

이번 세션에서 배운 것을 Memory Bank에 저장하세요.

아래 카테고리에 해당하는 것이 있으면 JSON 배열로 만들어 실행:
- decision: 기술/아키텍처 선택과 그 이유
- pattern: 발견한 코딩 패턴/컨벤션
- error: 만난 에러와 해결 방법
- constraint: 발견한 프로젝트 제약사항
- self-improve: scaffold/파이프라인 개선이 필요한 패턴

```bash
python scripts/extract-facts.py --save-json '[{"type":"...","fact":"...","confidence":0.8,"tags":["..."]}]'
```

해당 사항이 없으면 스킵하세요.
PROMPT

exit 0
