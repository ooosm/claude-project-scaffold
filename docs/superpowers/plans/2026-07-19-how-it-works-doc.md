---
related: [DEC-009]
spec: docs/superpowers/specs/2026-07-19-how-it-works-doc-design.md
status: done
date: 2026-07-19
---

# 구현 계획: How It Works 문서 추가

## 개요

동작 원리(동적 흐름) 납품 문서를 스캐폴드에 추가하고 방법론 룰에 연동한다(DEC-009).

## 작업 분해 (Tasks)

1. **문서 골격** — `docs/how-it-works.md` (Mermaid 워크드 예시 2종) (완료)
2. **readme-sync 연동** — 업데이트 트리거 + 갱신 묶음 7(조건부) + 릴리즈 절차 (완료)
3. **문서 분류 등록** — CLAUDE.md 표 · README 구조/표 · project-init 분류(정적 vs 동적) (완료)
4. **추적성** — requirements에 큰 기능 ↔ how-it-works 상호 링크 (완료)
5. **check-docs** — 플레이스홀더 대상에 how-it-works 추가 (완료)
6. **DEC-009** — 위치·타이밍 결정 기록 (완료)

## 변경 파일

- `docs/how-it-works.md`(신규), `.claude/rules/readme-sync.md`·`requirements.md`·`project-init.md`,
  `.claude/CLAUDE.md`, `README.md`, `scripts/check-docs.sh`, `.claude/decisions/decision-log.md`

## 검증 계획

- 문서 변경(코드 아님) → 자동 테스트 비대상. 수동 검증: `check-docs.sh --strict` 통과 + Mermaid 문법 확인.

## 완료 시 갱신 묶음

- [x] 자동 갱신 묶음(정본: `readme-sync.md`) — 문서 등록/구조 반영
- [x] `scripts/check-docs.sh` 통과
- [x] 의존성 변경 없음
