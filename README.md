# OpenSmith

자율 자가개선 개발 아키텍처 — Claude Code 플러그인.

PRD 작성부터 설계, 구현, QA, 배포까지 전체 개발 파이프라인을 자동화합니다.

---

## 설치

```bash
# 1. 마켓플레이스 등록
claude plugin marketplace add mohitto55/opensmith

# 2. 플러그인 설치 (프로젝트 단위)
claude plugin install opensmith@opensmith-marketplace --scope project

# 3. 플러그인 로드
/reload-plugins
```

전역 설치 (모든 프로젝트에서 사용):
```bash
claude plugin install opensmith@opensmith-marketplace --scope user
```

---

## 사용법

### 1단계: PRD 작성

```
/opensmith:prd 커뮤니티 플랫폼
```

대화형으로 질문하며 시스템 PRD를 작성합니다.
- Phase 1~3: 핵심 정의, 범위, 심화 질문
- Phase 4~5: PRD 생성 + 사용자 검토
- Phase 6: 프로젝트 설정 자동 생성 (.opensmith/config.json, scaffold 패턴)

산출물: `docs/prd/system-prd.md`

### 2단계: 기능 구현

```
# 기능 하나만
/opensmith:execute 좋아요 기능

# PRD의 미구현 기능 전부 순차 실행
/opensmith:execute --all
```

`--all`은 system-prd.md의 기능 목록(Section 9)에서 미구현 기능을 순서대로 전부 실행합니다:

```
F-1: step0→1→2→3→4→5→6→7→8→9 ✅
  ↓ (자동으로 다음 기능)
F-2: step0→1→2→3→4→5→6→7→8→9 ✅
  ↓
F-3: step0→...→9 ✅
  ↓
"전체 기능 구현 완료!"
```

### execute 파이프라인 (10 스텝)

| Step | 이름 | 하는 일 |
|------|------|---------|
| 0 | Read PRD | 시스템 PRD 읽기, 미해결 Bug/TODO 확인, GitHub 동기화 |
| 1 | Feature PRD | 세분화 PRD 생성 (없으면 자동 생성) |
| 2 | Collect | Memory Bank + 코드베이스 + 문서 + GitHub 4-소스 검색 |
| 3 | Design | 비기능 요구사항 + 대규모 아키텍처 설계 |
| 4 | Approve | 사용자 승인 (승인 없이 구현 안 함) |
| 5 | Implement | 7역할 agent-teams로 구현 |
| 6 | Build | 빌드 검증 (최대 3회 재시도) |
| 7 | QA | QA 테스트 (**생략 불가**) |
| 8 | Deploy | 배포 (사용자 승인 후) |
| 9 | Report | 완료 보고 + PRD 상태 갱신 + Memory Bank 팩트 자동 추출 |

### 기타 옵션

```
/opensmith:execute --resume     # 중단된 곳부터 재개
/opensmith:execute --from 3     # step3부터 시작
```

### 3단계: Memory Bank 초기화 (선택)

```
/opensmith:init-memory
```

과거 대화에서 의사결정/에러/패턴을 학습하여, execute 시 자동으로 관련 컨텍스트를 제공합니다.

필요 패키지: `pip install sentence-transformers sqlite-vec`

---

## 알림 설정 (Slack / Discord / Telegram)

빌드 실패, QA 결과, 배포 완료 등의 이벤트를 자동으로 알림 받을 수 있습니다.

### 설정 방법 3가지

**방법 1: 환경변수 (가장 간단)**

```bash
# .bashrc, .zshrc, 또는 .env에 추가
export OPENSMITH_SLACK_WEBHOOK="https://hooks.slack.com/services/T.../B.../xxx"
export OPENSMITH_DISCORD_WEBHOOK="https://discord.com/api/webhooks/123/abc"
export OPENSMITH_TELEGRAM_TOKEN="123456:ABC-DEF..."
export OPENSMITH_TELEGRAM_CHAT_ID="987654321"
```

**방법 2: .opensmith/config.json (프로젝트별)**

`/opensmith:prd` Phase 6에서 자동 생성되는 config에 추가하거나 직접 편집:

```json
{
  "notifications": {
    "slack_webhook": "https://hooks.slack.com/services/...",
    "discord_webhook": "https://discord.com/api/webhooks/...",
    "telegram_token": "123456:ABC-DEF...",
    "telegram_chat_id": "987654321"
  }
}
```

**방법 3: 플러그인 설치 시**

`claude plugin install` 할 때 프롬프트로 입력. 민감 정보(webhook URL)는 시스템 키체인에 저장됩니다.

### 알림이 발송되는 이벤트

| 이벤트 | 시점 |
|--------|------|
| `build_success` | 빌드 성공 (step6) |
| `build_fail` | 빌드 3회 실패 (step6) |
| `qa_pass` | QA 통과 (step7) |
| `qa_fail` | QA 실패 (step7) |
| `deploy_success` | 배포 성공 (step8) |
| `deploy_fail` | 배포 실패 (step8) |
| `feature_done` | 기능 구현 완료 (step9) |
| `pipeline_done` | --all 전체 완료 (step9) |
| `escalation` | 3단계 에스컬레이션 |

### 수동 알림 테스트

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh --event build_success --message "테스트 알림"
```

설정하지 않은 채널은 자동으로 스킵됩니다. 하나도 설정하지 않아도 파이프라인은 정상 동작합니다.

---

## 스킬 목록

| 스킬 | 설명 |
|------|------|
| `/opensmith:prd` | 대화형 시스템 PRD 작성 |
| `/opensmith:execute` | 전체 기능 파이프라인 (PRD → 구현 → QA → 배포) |
| `/opensmith:init-memory` | Memory Bank 초기화 |
| `/opensmith:agent-teams` | 7역할 팀 오케스트레이터 |
| `/opensmith:bug-tracker` | 버그 수집/추적 (bugs.json) |
| `/opensmith:deploy` | K8s 배포 |
| `/opensmith:qa-test` | 브라우저 QA 테스트 |
| `/opensmith:scaffold-update` | scaffold 패턴 수동 업데이트 |
| `/opensmith:self-improve` | 자가개선 루프 실행 |
| `/opensmith:merge-worktree` | 워크트리 스쿼시 머지 |

---

## 7역할 팀 (agent-teams)

| 역할 | Phase | 하는 일 |
|------|-------|---------|
| 팀 리더 | 전체 | 오케스트레이션, 모니터링, 리뷰 |
| 설계자 | 0-1 | API + 데이터 모델 설계 |
| UI 디자이너 | 1-2 | 와이어프레임, 컴포넌트 명세, 반응형 |
| DB 관리자 | 1-2 | 스키마, 인덱스, 마이그레이션 |
| 프론트엔드 | 2-3 | UI 명세 기반 컴포넌트 구현 |
| 백엔드 | 2-3 | API 엔드포인트 + 서비스 구현 |
| QA | 4 | L0~L5 테스트 |

---

## 30 Hooks

| 티어 | 개수 | 동작 |
|------|------|------|
| HARD | 8 | 위반 시 차단 (보안, 패턴, 크기, 타입, 린트) |
| AGENT | 6 | 자동 수정 (빌드, 테스트, 타입, scaffold, 배포, 머지) |
| SOFT | 16 | 경고/컨텍스트 주입 (세션 복원, 팩트 추출, WIP 커밋 등) |

---

## Memory Bank

SQLite + sqlite-vec 기반 시맨틱 검색 시스템.

- **대화 인덱싱**: JSONL → exchange 쌍 → 384-dim 임베딩
- **팩트 추출**: 파이프라인 완료 시 Claude Code가 직접 의사결정/에러/패턴 자동 추출 (외부 API 불필요)
- **하이브리드 검색**: 벡터 유사도 + FTS → RRF(Reciprocal Rank Fusion) 결합
- **자동 통합**: 중복 감지, 모순 교체, 팩트 진화 추적

---

## 프로젝트 구조

```
opensmith/
├── .claude-plugin/
│   ├── plugin.json              # 플러그인 메타데이터
│   └── marketplace.json         # 마켓플레이스 정의
├── skills/
│   ├── prd/SKILL.md             # PRD 작성
│   ├── execute/                 # 파이프라인 오케스트레이터
│   │   ├── SKILL.md
│   │   ├── chain-hook.sh        # 스텝 체이닝
│   │   └── steps/step0~9.md     # 독립 서브스킬
│   ├── shared/                  # 공용 서브스킬
│   ├── agent-teams/SKILL.md     # 7역할 팀
│   ├── init-memory/SKILL.md     # Memory Bank 초기화
│   ├── deploy/SKILL.md
│   ├── qa-test/SKILL.md
│   └── (기타)
├── hooks/
│   ├── hooks.json               # 훅 등록
│   ├── hard/ (8개)
│   ├── agent/ (6개)
│   ├── soft/ (16개)
│   └── lib/                     # memory-query.sh 등
├── scripts/
│   ├── init-db.py               # DB 스키마 생성
│   ├── parse-conversations.py   # 대화 파서
│   ├── embed.py                 # 임베딩 생성
│   ├── extract-facts.py         # 팩트 추출
│   └── requirements.txt
├── docs/                        # 아키텍처 설계 문서
└── README.md
```

---

## 업데이트

```bash
# 마켓플레이스 업데이트
claude plugin marketplace update opensmith-marketplace

# 세션 내에서 즉시 반영
/reload-plugins
```

---

## License

MIT
