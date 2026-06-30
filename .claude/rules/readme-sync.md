# README & 사용자 가이드 동기화 (Docs Sync)

> 방법론 구성요소 ⑥ 사용자 가이드 — 실제 구현 근거로 작성·관리

## 기본 원칙

기능이 추가/변경되어 머지될 때마다, **실제 구현된 동작을 근거로**(추측 금지, 코드/엔드포인트
확인 후) `README.md`와 사용자 가이드(`.claude/docs/10-user-guide.md`)를 갱신한다.
사용자가 별도 요청하지 않아도 자동으로 수행한다.

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

태스크/단계 완료 시 아래를 **함께** 갱신한다:

```
1. .claude/docs/01-requirements.md  — 구현 현황 요약 표 (✅/⚠️/❌)
2. .claude/workspace/todo.md        — 진행/완료 이동 + 날짜
3. .claude/workspace/changelog.md   — 상세 이력 추가
4. README.md                        — Features/Changelog/Config (사용자 영향 시)
5. .claude/docs/10-user-guide.md    — 실제 동작 근거로 갱신
```

## 주의

- 기존 README의 커스텀 섹션·배지(badge)는 삭제하지 않는다.
- 마케팅성 문구·팀 소개 등 비기술적 내용은 건드리지 않는다.
- 확신이 없으면 수정 전 사용자에게 확인한다.
