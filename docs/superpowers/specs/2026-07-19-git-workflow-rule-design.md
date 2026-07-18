---
related: [DEC-008]
status: done
date: 2026-07-19
---

# 설계: Git 워크플로 룰 추가 (위험도 기반 브랜치 전략)

## 문제 / 목표

1인 개발에서 "항상 브랜치+PR" vs "항상 메인"의 단일 규칙은 각각 과잉 의식/메인 불안정의
문제가 있다. 위험도에 따라 분기하는 하이브리드 규칙을 방법론 룰로 못 박아, 안전 변경은
빠르게·위험 변경은 격리하고, PR을 harness 게이트로 연결한다.

## 요구사항 연결

- 방법론 룰 확장(코드 기능 아님) → REQ/FR 신규 없음. 문서/규범 변경.

## 설계

- 신규 룰 파일 `.claude/rules/git-workflow.md`: 위험도 분기 규칙 + 브랜치 네이밍 +
  PR=게이트(브랜치 보호로 strict CI 승격) + Claude Code 연계 + 커밋 단위.
- `.claude/CLAUDE.md`의 @import 목록에 등록(방법론 룰 8종 → 9종).
- 참조 갱신: README·project-init·commands.md의 "룰 8종" 표기를 "9종"으로.
  (decision-log의 과거 DEC 표기는 append-only라 수정하지 않음.)
- UI 없음 → 목업 게이트 해당 없음.

## 검토한 대안

- 브랜치 전략: 항상 브랜치 / 항상 메인 / **위험도 하이브리드**(채택) — DEC-008.
- 배치: conventions.md 확장 vs **전용 파일**(채택, 발견성·응집성).

## 리스크 / 고려사항

- "8종" 표기가 여러 문서에 흩어져 있어 누락 위험 → grep으로 일괄 확인.
- 글로벌 룰(`~/.claude`)과 divergence 발생 → 미러링은 사용자 승인 후 별도 수행(DEC-002 방향).

## 완료 조건

- [x] `git-workflow.md` 작성 및 @import 등록
- [x] "룰 8종→9종" 참조 일괄 갱신(과거 DEC 제외)
- [x] `check-docs.sh --strict` 통과
- [x] DEC-008 기록
- 테스트: 문서 룰 변경으로 자동 테스트 비대상 → 수동 검증(check-docs + grep)으로 대체(→ validation.md 예외)
