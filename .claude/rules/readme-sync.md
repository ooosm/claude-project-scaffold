# README & 사용자 가이드 동기화 (Docs Sync)

> 방법론 구성요소 ⑥ 사용자 가이드 — 실제 구현 근거로 작성·관리

## 기본 원칙

기능이 추가/변경되어 머지될 때마다, **실제 구현된 동작을 근거로**(추측 금지, 코드/엔드포인트
확인 후) `README.md`와 사용자 가이드(`docs/user-guide.md`)를 갱신한다.
사용자가 별도 요청하지 않아도 자동으로 수행한다.
사용자 가이드는 **사람에게 전달되는 납품 문서**이므로 숨김 폴더가 아닌 `docs/`에 둔다.

## 업데이트 트리거

| 트리거 | 대상 |
|--------|------|
| 새 기능 추가 | README Features / 사용자 가이드 |
| 기존 기능 변경 | 해당 설명 수정 |
| API/인터페이스 변경 | Usage / API 섹션 |
| 설치 방법 변경 | Installation |
| 환경 변수 추가/삭제 | Configuration |
| 의존성 변경 | Prerequisites / Dependencies (+ DEC 근거) |
| 사용자 영향 있는 버그 수정 | Changelog |

> 내부 리팩토링·테스트 추가·코드 스타일 변경은 README를 수정하지 않는다.

## 2단 이력 관리

- `.claude/workspace/changelog.md` → **내부용 상세 기술 이력**(작업하며 즉시 누적).
- `README.md`의 Changelog → **외부 공개용 요약**(사용자에게 의미 있는 항목만).

작업 완료 후 changelog.md에 먼저 기록하고, 그중 의미 있는 항목만 README에 반영한다.

## 완료 시 자동 갱신 묶음 (한 번에)

> 이 목록이 갱신 묶음의 **단일 정본**이다. 다른 룰(`planning.md`·`requirements.md`·
> `validation.md`)과 plan 템플릿은 이 목록을 참조만 하고 재정의하지 않는다.

태스크/단계 완료 시 아래를 **함께** 갱신한다:

```
1. .claude/docs/01-impl-requirements.md — 구현 현황 요약 표 (✅/⚠️/❌)
2. .claude/workspace/todo.md            — 진행/완료 이동 + 날짜
3. .claude/workspace/changelog.md       — 상세 이력 추가
4. README.md                            — Features/Changelog/Config (사용자 영향 시)
5. docs/user-guide.md                   — 실제 동작 근거로 갱신
6. .claude/docs/02-architecture.md      — 구조가 바뀐 경우만
```

갱신 후 `scripts/check-docs.sh`로 정합성을 확인한다.

## 릴리즈 절차 (버전 끊기)

납품/배포 시점 또는 사용자 지시가 있을 때 릴리즈를 끊는다:

1. **버전 결정** — SemVer(`MAJOR.MINOR.PATCH`). 호환성 깨짐=MAJOR, 기능 추가=MINOR, 수정=PATCH.
2. **changelog 마감** — `workspace/changelog.md`의 `[Unreleased]` 항목을
   `## vX.Y.Z (YYYY-MM-DD)` 섹션으로 이동한다.
3. **README 반영** — 그중 사용자에게 의미 있는 항목을 README Changelog에 요약 이관.
4. **태그** — `git tag vX.Y.Z` (버전 결정에 트레이드오프가 있었으면 DEC 기록).
5. **납품물 확인** — `docs/user-guide.md`·README가 릴리즈 시점 실제 동작과 일치하는지 확인.

## 주의

- 기존 README의 커스텀 섹션·배지(badge)는 삭제하지 않는다.
- 마케팅성 문구·팀 소개 등 비기술적 내용은 건드리지 않는다.
- 확신이 없으면 수정 전 사용자에게 확인한다.
