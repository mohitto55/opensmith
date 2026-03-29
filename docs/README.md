# LoopyEra - Autonomous Self-Improving Architecture

> "가장 큰 병목은 사람이다."
> "사람은 방향을 정하고, 시스템이 스스로 만든다."

## 개요

LoopyEra는 {{PROJECT_NAME}} 프로젝트에 적용하는 **자율 자가개선 아키텍처**입니다.
Claude Code의 훅, 스킬, 메모리, 에이전트 시스템을 유기적으로 결합하여
사람의 개입 없이도 코드 품질을 유지하고, 에러를 자동 수정하며, 패턴을 학습하는 시스템을 구축합니다.

---

## 문서 구조

| 문서 | 설명 |
|------|------|
| [PRD (Product Requirements Document)](./prd.md) | 전체 시스템 요구사항 정의 |
| [5-Layer Architecture](./architecture-5layer.md) | 5개 레이어 아키텍처 상세 |
| [Context Stack](./context-stack.md) | 프롬프트 컨텍스트 스택 설계 |
| [Hook System](./hook-system.md) | 30개 훅 시스템 상세 |
| [Memory Bank](./memory-bank.md) | Memory Bank 데이터 파이프라인 |
| [Self-Improvement Loop](./self-improvement-loop.md) | 자가개선 순환 구조 |
| [Escalation System](./escalation-system.md) | 3단계 에스컬레이션 |
| [Team Orchestrator](./team-orchestrator.md) | /team 6역할 오케스트레이터 |
| [Worktree Management](./worktree-management.md) | 워크트리 + WIP 커밋 자동화 |

---

## 핵심 수치 목표

| 지표 | 현재 | 목표 |
|------|------|------|
| 훅 | 1개 | 30개 |
| 이벤트 | 1개 | 11개 |
| 스킬 | 9개 | 65개 |
| 팩트 (Memory Bank) | 0개 | 2,600+ |
| 대화 기록 | 0건 | 50K+ |

---

## 사용자의 역할: 방향 설정자, 실행자가 아닌

### 하는 일
- 방향과 목표 설정
- 양질의 피드백 제공
- 정보 제공 (아티클, 레포)
- 텔레그램 알림 대응
- self-improve 제안 검토

### 안 하는 일
- 코드 작성
- 스킬 생성 (스킬이 스킬을 만듦)
- 버그 수정 (3단계가 처리)
- 테스트 실행 (훅이 자동 검증)
- 도구 실행 승인

---

## 관련 문서
- [시스템 아키텍처](../architecture.md) - 서비스 인프라
- [개발 진행 상황](../dev-progress.md) - 현재 개발 상태
- [기능 명세](../features.md) - 서비스 기능
