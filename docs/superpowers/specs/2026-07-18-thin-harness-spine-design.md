---
related: [DEC-006, DEC-007]
status: done
date: 2026-07-18
---

# 설계: 얕은 harness 척추 (Thin Harness Spine)

## 문제 / 목표

이 레포는 지금까지 사실상 정적 스캐폴드(읽는 문서)였고, 강제력이 전부 프롬프트 텍스트에
의존했다. 저비용·고신뢰 불변식만 골라 **실제로 실행·강제되는 얇은 층**을 얹어,
"스캐폴드 + 얕은 harness"로 정의를 승격한다. 판단이 필요한 게이트(목업·brainstorming)는
권고로 남긴다.

## 요구사항 연결

- 개념 정의: README에 "사람 개발자 + 코딩 에이전트를 위한 스캐폴드 겸 얕은 harness" 명시.
- 강제 3종: ① Stop hook(비차단) 배선 ② 슬래시 커맨드 2개(`/dec`·`/new-feature`) ③ CI(strict).

## 설계

- **check-docs 템플릿 자기감지**: 루트에 `_skeleton-README.md`가 있으면 = 스캐폴드 템플릿
  자신 → 플레이스홀더 검사를 건너뛴다(골격의 플레이스홀더는 정상). 대상 프로젝트는
  부트스트랩 때 이 파일을 지우므로 자동으로 플레이스홀더 검사가 켜진다. 구조 검사
  (REQ/FR 참조·DEC 번호)는 항상 수행.
- **Stop hook**: `.claude/settings.json`에 비차단(warn-only) Stop hook. check-docs는 기본
  exit 0이라 세션을 막지 않는다. 차단은 CI(`--strict`)가 담당 → 로컬은 부드럽게, 원격은 엄격.
- **슬래시 커맨드 = harness 동사**: 프롬프트 템플릿이 아니라 헬퍼 스크립트를 호출해
  결정론적 동작을 보장.
  - `/dec <제목>` → `scripts/new-dec.sh`가 **다음 DEC 번호를 원자적으로 할당**(병렬 세션
    번호 충돌 해소) + 골격 append. 에이전트가 내용을 채운다.
  - `/new-feature <slug>` → `scripts/new-feature.sh`가 오늘 날짜로 spec/plan 골격 생성 →
    에이전트가 brainstorming 게이트로 채운다.
- **CI**: `.github/workflows/check-docs.yml`가 push/PR에서 `check-docs.sh --strict` 실행.
  템플릿 자기감지 덕에 스캐폴드 레포 자신도 통과(구조 검사만), 대상 프로젝트는 전체 검사.

## 검토한 대안

- Stop hook 차단 vs 비차단 → 비차단(DEC-006). 로컬 차단은 이질적 프로젝트에서 거슬리고 취약.
- 슬래시 커맨드 순수 프롬프트 vs 스크립트 호출 → 스크립트(DEC-007). 원자성·결정론 확보.
- CI에서 플레이스홀더 검사 강제 vs 템플릿 자기감지 → 자기감지. 스캐폴드 CI가 항상 red 되는 문제 회피.

## 리스크 / 고려사항

- 스크립트 이식성(BSD/GNU sed) → `sed -i.bak` 후 삭제로 양쪽 호환.
- Stop hook 명령이 대상 프로젝트에 복사됨 → 스크립트 부재 시 무해하게 통과하도록 가드.

## 완료 조건

- [x] README 정의 섹션 추가
- [x] check-docs 템플릿 자기감지 → 스캐폴드 자신 `--strict` 통과
- [x] Stop hook 배선(비차단)
- [x] `/dec`·`/new-feature` + 헬퍼 스크립트
- [x] CI 워크플로
- [x] DEC-006·007 기록(→ new-dec.sh로 dogfood)
