---
description: 새 작업 사이클 시작 — spec/plan 골격 생성 후 brainstorming 게이트로 진입
argument-hint: <기능-slug>
allowed-tools: Bash(bash scripts/new-feature.sh:*), Read, Edit
---

새 기능/작업 사이클을 시작한다. slug: **$ARGUMENTS**

1. `bash scripts/new-feature.sh "$ARGUMENTS"` 를 실행한다.
   → 오늘 날짜로 spec/plan 골격이 `docs/superpowers/`에 생성된다.
2. **brainstorming 게이트**: 생성된 spec을 근거로 문제/목표 · 요구사항 연결(REQ/FR) ·
   설계 · 검토한 대안을 채운다. UI가 포함되면 **목업 게이트**(→ `.claude/rules/ui-mockups.md`)를
   반드시 통과한다(목업 승인 없이 UI 코드 금지).
3. **writing-plans**: plan에 작업을 독립 검증 가능한 태스크로 분해하고,
   `.claude/workspace/todo.md`에 BACKLOG/태스크로 등록한다.
4. 코딩은 spec/plan **승인 후** 시작한다("먼저 생각하고, 나중에 코딩한다").
5. 구현 중 결정이 생기면 `/dec`로 즉시 기록한다.
