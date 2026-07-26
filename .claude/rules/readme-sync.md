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
| **큰 기능의 동작 흐름 추가/변경** | **`docs/how-it-works.md`** (트리거→컴포넌트 흐름) |

> 내부 리팩토링·테스트 추가·코드 스타일 변경은 README를 수정하지 않는다.
> how-it-works는 **큰 기능 단위 흐름**에만 반응한다(단일 컴포넌트·소규모 변경은 대상 아님).

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
6. .claude/docs/02-architecture.md      — 구조(정적)가 바뀐 경우만
7. docs/how-it-works.md                 — 큰 기능의 동작 흐름(동적)이 바뀐 경우만
```

> 6·7은 조건부다. architecture는 **정적 구조**(무엇이 있나), how-it-works는 **동적 흐름**
> (트리거별로 어떻게 동작하나) — 서로 상보적이며 상호 링크한다.

갱신 후 `scripts/check-docs.sh`로 정합성을 확인한다.

## 릴리즈 절차 (버전 끊기)

납품/배포 시점 또는 사용자 지시가 있을 때 릴리즈를 끊는다. **손으로 하지 말고 `/release`를 쓴다**
— 버전 SoT·changelog·README 세 곳을 동시에 맞춰야 하는데, 손으로 하면 어긋나고 그 어긋남을
`check-docs` §6이 잡는다.

1. **changelog 최신화** — `workspace/changelog.md`의 `[Unreleased]`가 이번 릴리즈 변경을
   **실제 구현 근거로** 담고 있는지 먼저 확인한다(추측 금지).
2. **버전 결정 + `/release`** — SemVer(`MAJOR.MINOR.PATCH`). 호환성 깨짐=MAJOR, 기능 추가=MINOR,
   수정=PATCH. `/release major|minor|patch`가 버전 SoT bump(쓰기 후 재검증) + `[Unreleased]`
   마감 + README Changelog 골격 삽입까지 한다.
3. **README 요약 채움** — 삽입된 골격에 사용자에게 의미 있는 항목만 골라 옮긴다.
   안 채우면 플레이스홀더가 남아 `check-docs` §1이 잡는다(strict CI가 릴리즈 커밋을 차단).
4. **납품물 확인** — `docs/user-guide.md`·`docs/how-it-works.md`·README가 릴리즈 시점 실제
   동작과 일치하는지 확인(how-it-works는 납품 주고받는 쪽의 동작 이해 문서이므로 특히 중요).
5. **커밋·태그** — 사용자에게 확인받고 `git commit -am "chore: release vX.Y.Z"` → `git tag vX.Y.Z`.
   `/release`는 git 부작용을 만들지 않는다(→ `git-workflow.md`).
   버전 결정에 트레이드오프가 있었으면 DEC로 기록한다.

> 버전 SoT는 자동 감지되고 정책은 `commands.md`의 `## 버전 정책`에서 override한다.
> 릴리즈 개념이 없는 프로젝트는 `version-policy: none`으로 버전 검사를 끄되, **changelog는
> 계속 쌓는다** — 스테일 검사(§5)는 정책과 무관하게 동작한다.

## 주의

- 기존 README의 커스텀 섹션·배지(badge)는 삭제하지 않는다.
- 마케팅성 문구·팀 소개 등 비기술적 내용은 건드리지 않는다.
- 확신이 없으면 수정 전 사용자에게 확인한다.
