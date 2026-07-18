---
description: 새 결정(DEC)을 원자적 번호 할당으로 decision-log에 기록
argument-hint: <결정 제목>
allowed-tools: Bash(bash scripts/new-dec.sh:*), Read, Edit
---

새 설계·구현 결정을 기록한다. 결정 제목: **$ARGUMENTS**

1. `bash scripts/new-dec.sh "$ARGUMENTS"` 를 실행한다.
   → 다음 DEC 번호를 **원자적으로 할당**하고 `.claude/decisions/decision-log.md` 끝에 골격을 추가한다
   (병렬 세션의 번호 충돌 예방). 손으로 번호를 매기지 말 것.
2. 방금 추가된 `## DEC-NNN` 항목을 열어 아래를 **실제 내용**으로 채운다
   (규칙: `.claude/rules/decisions.md`):
   - **맥락**: 어떤 상황/문제에서 결정이 필요했는가
   - **결정**: 무엇을 선택했는가(한 줄로 명확히)
   - **검토한 대안**: 채택 1건 + 기각 N건, 각각 **이유** 포함 — "왜 기각했는가"는 필수
   - **성능·향후 영향**: 이 선택이 성능/확장성/유지보수에 미치는 영향(필수)
   - **출처**: 관련 spec/plan/BACKLOG-NNN
3. 큰 아키텍처 결정이면 `ADR-000-template.md`를 복사해 ADR도 함께 남긴다.
