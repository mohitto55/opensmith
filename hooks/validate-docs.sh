#!/bin/bash
# 문서 구조 검증 훅
# pre-commit 시 docs/ 폴더의 문서가 필수 구조를 갖추었는지 검증

set -e

DOCS_DIR="docs"
ERRORS=()
WARNINGS=()

# 색상 코드
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# =============================================
# 1. 문서별 필수 섹션 정의
# =============================================

declare -A REQUIRED_SECTIONS

# Add project-specific required sections here
# Example:
# REQUIRED_SECTIONS["architecture.md"]="서버 구성|기술 스택|관련 문서"
# REQUIRED_SECTIONS["features.md"]="관련 문서"

# =============================================
# 2. 변경된 docs/ 파일만 검증 대상으로 선정
# =============================================

CHANGED_DOCS=$(git diff --cached --name-only --diff-filter=ACM | grep "^docs/.*\.md$" || true)

if [ -z "$CHANGED_DOCS" ]; then
    exit 0
fi

echo -e "${GREEN}문서 구조 검증 시작...${NC}"
echo ""

# =============================================
# 3. 각 문서 검증
# =============================================

for doc in $CHANGED_DOCS; do
    filename=$(basename "$doc")

    # 3-1. 파일이 비어있는지 확인
    if [ ! -s "$doc" ]; then
        ERRORS+=("[$filename] 파일이 비어있습니다")
        continue
    fi

    # 3-2. H1 제목(# ) 존재 확인
    if ! grep -q "^# " "$doc"; then
        ERRORS+=("[$filename] H1 제목(# )이 없습니다")
    fi

    # 3-3. 필수 섹션 검증
    if [ -n "${REQUIRED_SECTIONS[$filename]}" ]; then
        IFS='|' read -ra SECTIONS <<< "${REQUIRED_SECTIONS[$filename]}"
        for section in "${SECTIONS[@]}"; do
            if ! grep -q "## .*${section}" "$doc" && ! grep -q "^## ${section}" "$doc"; then
                ERRORS+=("[$filename] 필수 섹션 누락: '## ${section}'")
            fi
        done
    fi

    # 3-4. '관련 문서' 섹션에 실제 링크가 있는지 확인
    if grep -q "## 관련 문서" "$doc"; then
        # 관련 문서 섹션 이후에 마크다운 링크가 하나 이상 있어야 함
        related_section=$(sed -n '/^## 관련 문서/,/^## /p' "$doc" | head -20)
        if ! echo "$related_section" | grep -q "\[.*\](.*\.md)"; then
            WARNINGS+=("[$filename] '관련 문서' 섹션에 링크가 없습니다")
        fi
    fi

    # 3-5. 관련 문서 링크가 실제 파일을 가리키는지 확인
    links=$(grep -oP '\(\.\/[^)]+\.md\)' "$doc" 2>/dev/null || true)
    for link in $links; do
        target=$(echo "$link" | sed 's/[()]//g')
        target_path="$DOCS_DIR/$target"
        # ./으로 시작하면 제거
        target_path=$(echo "$target_path" | sed 's|docs/\./|docs/|')
        if [ ! -f "$target_path" ]; then
            WARNINGS+=("[$filename] 깨진 링크: $target")
        fi
    done

    # 3-6. docs/README.md에 새 문서가 등록되어 있는지 확인
    if [ "$filename" != "README.md" ] && [ -f "$DOCS_DIR/README.md" ]; then
        if ! grep -q "$filename" "$DOCS_DIR/README.md"; then
            WARNINGS+=("[$filename] docs/README.md 인덱스에 등록되지 않았습니다")
        fi
    fi

    echo -e "  $filename 검증 완료"
done

# =============================================
# 4. 결과 출력
# =============================================

echo ""

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}경고 (${#WARNINGS[@]}건):${NC}"
    for warn in "${WARNINGS[@]}"; do
        echo -e "  $warn"
    done
    echo ""
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}오류 (${#ERRORS[@]}건):${NC}"
    for err in "${ERRORS[@]}"; do
        echo -e "  $err"
    done
    echo ""
    echo -e "${RED}문서 구조 검증 실패! 위 오류를 수정한 후 다시 커밋하세요.${NC}"
    exit 1
fi

echo -e "${GREEN}문서 구조 검증 통과!${NC}"
exit 0
