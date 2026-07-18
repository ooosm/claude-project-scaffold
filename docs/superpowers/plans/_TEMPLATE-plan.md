---
related: [BACKLOG-NNN, REQ-N-M, FR-NN, DEC-NNN]
spec: docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md
status: draft
date: YYYY-MM-DD
---

# 구현 계획: [기능/작업명]

> writing-plans 산출물 = **작업 분해**. 파일명: `YYYY-MM-DD-<slug>.md`.
> 설계 정본(spec)을 근거로 작성한다. 이 파일은 템플릿이다.

## 개요
이 계획이 무엇을 구현하는가(spec 한 줄 요약 + 연결 ID).

## 작업 분해 (Tasks)
순서대로, 각 태스크는 독립 검증 가능하게.

1. **[Task 1]** — 변경 파일: `...` / 완료: 테스트 통과
2. **[Task 2]** — ...
3. **[Task 3]** — ...

## 변경 파일
- `src/...` — [변경 이유]

## 검증 계획
- 단위/통합 테스트, 수동 확인 항목(→ `.claude/rules/validation.md`).

## 완료 시 갱신 묶음
- [ ] 자동 갱신 묶음 수행(목록 정본: `.claude/rules/readme-sync.md`)
- [ ] `scripts/check-docs.sh` 통과
- [ ] 의존성 변경 시 DEC + README Prerequisites
