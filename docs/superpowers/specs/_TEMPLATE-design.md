---
related: [BACKLOG-NNN, REQ-N-M, FR-NN, DEC-NNN]
status: draft
date: YYYY-MM-DD
---

# 설계: [기능/작업명]

> brainstorming 산출물 = **설계 정본**. 파일명: `YYYY-MM-DD-<slug>-design.md`.
> 이 파일은 템플릿이다 — 실제 spec은 새 파일로 복사해 작성한다.

## 문제 / 목표
무엇을 왜 만드는가(맥락 포함).

## 요구사항 연결
- 구현 관점: REQ-N-M (`.claude/docs/01-requirements.md`)
- 사용자 관점: FR-NN (`.claude/docs/01-a-func_requirements.md`)

## 설계
- 접근 방식 / 핵심 아이디어
- 데이터 구조 / 인터페이스 / 엔드포인트
- (UI 포함 시) **HTML 목업 게이트 통과 여부** — 목업 링크: `./mockups/...`

## 검토한 대안
주요 대안과 선택 이유 — 결정은 `DEC-NNN`으로 `decision-log.md`에도 기록.

## 리스크 / 고려사항
사이드 이펙트, 의존성 변경, 호환성.

## 완료 조건
- [ ] [검증 가능한 조건]
- [ ] 테스트 작성 및 통과
