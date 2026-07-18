---
related: [DEC-002, DEC-003, DEC-004, DEC-005]
spec: (본 세션의 스캐폴드 점검 리포트 — 대화 내 검토 결과가 설계 근거)
status: done
date: 2026-07-18
---

# 구현 계획: 스캐폴드 점검 결과 반영 (문서 구조·정합성 개선)

## 개요

2026-07-18 스캐폴드 전수 점검에서 발견된 문제를 우선순위 순으로 반영한다.
사용자 승인: "전부 권장 순서대로 진행" (2026-07-18).

## 작업 분해 (Tasks)

1. **[P1] 글로벌 룰 병합·충돌 해소** — 변경: `~/.claude/CLAUDE.md`, `~/.claude/rules/*`
   - 신규 3종(decisions·requirements·ui-mockups) 글로벌 복사, 기존 5종 항목 보강 병합
   - 우선순위 선언(프로젝트 룰 우선) 추가, plan 경로 충돌 해소
2. **[P2] 참조-실체 불일치 해소** — 변경: `.claude/settings.json`(신규),
   `.claude/docs/02-architecture.md`(신규), `.claude/rules/commands.md`(신규),
   `01-user-requirements.md` 헤더, `decision-log.md` 레포명, CLAUDE.md/README 표 갱신
3. **[P3] 강제력 수단 동봉 + 갱신 묶음 중복 제거** — 신규: `scripts/check-docs.sh`
   - 갱신 묶음 정의를 `readme-sync.md` 단일 정본으로, 나머지는 참조만
4. **[P4] 납품 관점 보강** — `10-user-guide.md` → `docs/user-guide.md` 이동 + 참조 갱신,
   릴리즈 절차 규칙 추가, REQ 검증방법에 테스트 참조 형식, 테스트 불가 작업 carve-out
5. **[P5] 룰 미세 보강** — REQ ID 불변 규칙, TUI 목업 예외, 문서 번호 규약, mockups/ 생성

## 검증 계획

- `scripts/check-docs.sh` 실행으로 자체 검증 (플레이스홀더·참조 무결성)
- 전 파일 상호 참조 수동 확인 (댕글링 참조 0건)

## 완료 시 갱신 묶음

- [x] 결정 로그(DEC-002~005) 기록
- [x] README.md 구조도·표 갱신
- [x] 본 plan status → done
