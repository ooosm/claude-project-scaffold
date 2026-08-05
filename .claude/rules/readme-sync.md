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
3. .claude/workspace/todo.md            — 관련 BACKLOG 행의 상태·근거 (해당 항목이 있을 때)
4. .claude/workspace/changelog.md       — 상세 이력 추가
5. README.md                            — Features/Changelog/Config (사용자 영향 시)
6. docs/user-guide.md                   — 실제 동작 근거로 갱신
7. .claude/docs/02-architecture.md      — 구조(정적)가 바뀐 경우만
8. docs/how-it-works.md                 — 큰 기능의 동작 흐름(동적)이 바뀐 경우만
```

> 7·8은 조건부다. architecture는 **정적 구조**(무엇이 있나), how-it-works는 **동적 흐름**
> (트리거별로 어떻게 동작하나) — 서로 상보적이며 상호 링크한다.

### 3번이 왜 2번과 따로 있나

같은 파일이지만 **다른 표**다. 2번은 태스크 목록, 3번은 **BACKLOG 표**다. 예전 목록은
`todo.md`를 "진행/완료 이동"이라고만 적어 BACKLOG 표는 대상이 아닌 것처럼 읽혔고, 실제로
파생 프로젝트에서 **구현·릴리즈까지 끝난 항목이 `진행중`으로 남아 있었다**. 갱신할 것이
없으면 넘어가되, 확인은 한다. 합치지 않는 이유는 체크리스트가 줄 단위로 소비되기 때문이다 —
절 안의 종속절은 건너뛰기 쉽다.

BACKLOG 행을 닫을 때는 **무엇을 근거로 닫았는지 한 줄**을 `근거` 열에 남긴다 — spec/plan
파일명·커밋 해시·확인 방법 중 무엇이든 좋다. "완료"만 적힌 행은 다음 사람이 다시 확인해야 한다.

| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-002 | 버전·changelog 정합성 harness | ✅ 완료(2026-07-27) | `2026-07-27-version-release-harness-design.md` |

> 이 항목은 `check-docs.sh` §7이 기계적으로 확인한다 — changelog의 `feat`/`fix` 항목이나
> 완료 체크박스(`- [x]`)가 언급한 BACKLOG인데 표가 미완료면 경고한다. 룰은 의도를 적고,
> 검사는 결과를 본다. BACKLOG 표가 없는 프로젝트에서는 검사 자체를 건너뛴다.

### 이 체크리스트로 막을 수 없는 것

**다른 작업의 부수 효과로 해소되는 항목**은 완료 시점 체크리스트로 잡히지 않는다. 고친
쪽에는 그 BACKLOG를 알 이유가 없기 때문이다. 같은 이유로, 항목을 쓸 당시의 관측이 그대로
굳는 경우도 있다(증상이 바뀌었는데 설명은 예전 그대로인 항목).

그래서 **주기적으로 BACKLOG를 코드에 대고 전수조사**한다 — 문서를 다시 읽는 게 아니라
실행하거나 소스를 확인하는 방식으로. 유효하다고 확인한 항목에도 **근거를 적어 두면** 다음
조사에서 같은 확인을 반복하지 않는다.

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
