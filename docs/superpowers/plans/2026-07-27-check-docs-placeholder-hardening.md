---
related: [DEC-010]
spec: docs/superpowers/specs/2026-07-27-check-docs-placeholder-hardening-design.md
status: done
date: 2026-07-27
---

# 구현 계획: check-docs 플레이스홀더 검출 고도화 + 회귀 테스트

## 개요

실사용 피드백(거짓 초록불)을 반영해 check-docs 플레이스홀더 검출을 넓히고, 회귀 테스트로
고정한다(DEC-010).

## 작업 분해 (Tasks)

1. **검출 규칙 교체** — `scripts/check-docs.sh`: `scan_placeholders()` 신설(비-ASCII 대괄호 +
   Mermaid 펜스 제외 + 로케일 독립 + 링크/각주 제외). (완료)
2. **회귀 테스트** — `scripts/test-check-docs.sh`: 임시 대상 프로젝트로 정탐/오탐/Mermaid/strict 단언. (완료)
3. **CI 배선** — `.github/workflows/check-docs.yml`에 테스트 스텝 추가. (완료)
4. **문서 등록** — README·project-init·commands.md·settings.json. (완료)
5. **DEC-010** — 검출 접근·트레이드오프 기록. (완료)

## 변경 파일

- `scripts/check-docs.sh`, `scripts/test-check-docs.sh`(신규),
  `.github/workflows/check-docs.yml`, `.claude/rules/commands.md`,
  `.claude/rules/project-init.md`, `README.md`, `.claude/settings.json`,
  `.claude/decisions/decision-log.md`

## 검증 계획

- `bash scripts/test-check-docs.sh` (기본 + `LC_ALL=C`) 전부 통과.
- 실제 스켈레톤 대상 시뮬레이션(_skeleton 숨김)에서 Mermaid 노드 라벨 오탐 0 확인.
- 스캐폴드 자신 `check-docs.sh --strict` 여전히 통과(템플릿 자기감지).

## 완료 시 갱신 묶음

- [x] 자동 갱신 묶음(정본: `readme-sync.md`) — README/구조 반영, 코드 변경엔 테스트 동반
- [x] `scripts/check-docs.sh` 통과 + `test-check-docs.sh` 통과
- [x] 의존성 변경 없음
