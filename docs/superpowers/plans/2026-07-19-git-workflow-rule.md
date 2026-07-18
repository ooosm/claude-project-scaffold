---
related: [DEC-008]
spec: docs/superpowers/specs/2026-07-19-git-workflow-rule-design.md
status: done
date: 2026-07-19
---

# 구현 계획: Git 워크플로 룰 추가

## 개요

위험도 기반 브랜치 전략을 방법론 룰(`git-workflow.md`)로 추가하고 참조를 정합화한다(DEC-008).

## 작업 분해 (Tasks)

1. **룰 파일 작성** — `.claude/rules/git-workflow.md` (완료)
2. **@import 등록** — `.claude/CLAUDE.md` 룰 목록에 추가 (planning 다음 위치)
3. **참조 갱신** — README·project-init·commands.md "룰 8종"→"9종" (과거 DEC 제외)
4. **DEC 기록** — `/dec`(new-dec.sh)로 DEC-008 발번 후 내용 작성
5. **검증** — `check-docs.sh --strict` 통과 + grep으로 "8종" 잔존 0 확인

## 변경 파일

- `.claude/rules/git-workflow.md` — 신규 룰
- `.claude/CLAUDE.md` — @import 등록
- `README.md`·`.claude/rules/project-init.md`·`.claude/rules/commands.md` — 참조 갱신
- `.claude/decisions/decision-log.md` — DEC-008

## 검증 계획

- 문서 룰 변경(코드 아님) → 자동 테스트 비대상. 수동 검증: `check-docs.sh --strict` + "8종" grep.

## 완료 시 갱신 묶음

- [x] 자동 갱신 묶음(정본: `readme-sync.md`) — 코드 기능 아님, README/구조 반영
- [x] `scripts/check-docs.sh` 통과
- [x] 의존성 변경 없음
