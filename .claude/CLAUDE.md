# [프로젝트명]

> 이 파일은 템플릿 스켈레톤입니다. 새 프로젝트에서 `[프로젝트명]`·`[개요]`를 실제 값으로 채우세요.
> **200줄 이하** 유지(초과 시 지시 준수율 저하). 상세 내용은 `@import`로 분리합니다.

## 개요

[한두 줄 요약: 무엇을 하는 서비스/도구인지]

## 핵심 원칙

- **Source of Truth**: [핵심 산출물이 무엇인지 — 예: `models/` 하위 JSON]. (포맷·위치를 한 줄로)
- **언어/스택**: [Node.js 20 LTS + TypeScript 5.x 등 — 호환 검증된 버전 명시]
- **표준/규약**: [준수할 외부 표준이 있으면 명시]

## 얕은 harness (강제 장치 — 손으로 하지 말 것)

이 레포는 스캐폴드 + 얕은 harness다. 규범(룰)은 권고지만 아래는 실제로 실행·강제된다.
- `/new-feature <slug>` — 새 작업 사이클 spec/plan 골격 생성
- `/dec <제목>` — 다음 DEC 번호 **원자 할당** + 골격(손으로 번호 매기지 말 것)
- `scripts/check-docs.sh` — 문서 정합성(로컬 Stop hook 비차단 / CI strict 차단). 상세: `@.claude/rules/commands.md`

## 상세 가이드 (방법론 룰 — 모든 세션에서 준수)

@.claude/rules/project-init.md
@.claude/rules/planning.md
@.claude/rules/requirements.md
@.claude/rules/decisions.md
@.claude/rules/ui-mockups.md
@.claude/rules/validation.md
@.claude/rules/conventions.md
@.claude/rules/readme-sync.md
@.claude/rules/commands.md

## 산출물 흐름 (단일 흐름)

```
아이디어
  └─ brainstorming → docs/superpowers/specs/YYYY-MM-DD-*-design.md   (설계 정본)
        └─ writing-plans → docs/superpowers/plans/YYYY-MM-DD-*.md     (작업 분해)
              └─ 구현 중 결정 → .claude/decisions/decision-log.md     (DEC-NNN)
              └─ 진행 현황   → .claude/workspace/todo.md              (BACKLOG/태스크)
              └─ 완료 시     → README / 사용자 가이드 / 구현현황표 갱신
```

- `.claude/` = **누적·영구**(결정·요구사항·아키텍처), `docs/superpowers/` = **작업 단위 산출물**.
- spec/plan 머리말에 관련 `BACKLOG-NNN`·`DEC-NNN`·`REQ-NNN`·`FR-NN`을 상호 참조로 명시.

## 설계/요구사항 문서

| 파일 | 내용 |
|------|------|
| `.claude/docs/01-impl-requirements.md` | 구현 관점 요구사항(REQ-N-M) + 구현 현황 요약 표 |
| `.claude/docs/01-user-requirements.md` | 사용자 관점 기능 요구사항(FR-NN, 체크박스) |
| `.claude/docs/02-architecture.md` | 아키텍처 스냅샷(구조 변경 시 갱신) |
| `docs/user-guide.md` | 사용자 가이드(사람용 납품 문서 — 실제 구현 근거로 갱신) |

> 문서 정합성 검사: `bash scripts/check-docs.sh` (명령어 목록: `@.claude/rules/commands.md`)

## 결정 로그 (`.claude/decisions/`)

| 파일 | 내용 |
|------|------|
| `decision-log.md` | **모든 설계·구현 결정 누적 로그**(DEC-NNN, append-only) |
| `ADR-000-template.md` | 큰 아키텍처 결정용 ADR 템플릿 |

> ⚠️ 대안 중 하나를 선택하는 결정을 내릴 때마다 **즉시** `decision-log.md`에 `## DEC-NNN`을 추가한다. 상세 규칙은 `@.claude/rules/decisions.md`.
