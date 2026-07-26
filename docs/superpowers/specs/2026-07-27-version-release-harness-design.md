---
related: [BACKLOG-002, DEC-011]
status: done
date: 2026-07-27
---

# 설계: 버전·changelog 정합성 harness

## 문제 / 목표

스캐폴드에 **릴리즈 절차는 문서로 존재하지만 강제 장치가 없다.** 그 결과 규칙이 실제로 지켜지지
않는다는 것이 이 레포 자신의 히스토리로 증명된다:

| 항목 | harness | 실제 결과 |
|------|---------|-----------|
| DEC 로그 | `/dec` + check-docs 번호 검사 | 6개 커밋에서 갱신, DEC-001~010 누적 |
| todo.md | 없음 | 2개 커밋에서 갱신 |
| changelog.md | 없음 | **초기 커밋 이후 0회 갱신**(골격 그대로) |
| git tag | 없음 | **0개** |

즉 느슨한 원인은 "버전 체계가 없어서"가 아니라 **`readme-sync.md`의 자동 갱신 묶음 3번
(changelog)이 강제되지 않아서**다. changelog가 안 쌓이면 릴리즈를 끊을 재료 자체가 없으므로
우선순위는 `changelog 강제 → 버전 정합성` 순이다.

**목표**: 기존 harness 척추(스크립트 + 슬래시 커맨드 + check-docs + Stop hook/CI)에 새 개념을
늘리지 않고 얹어, 버전과 changelog의 기계적 정합성을 강제한다.

### 범위 밖 (명시적 제외)

- calver 자동 bump 규칙 — 정책 선언과 형식 검사 제외만 지원(YAGNI).
- 커밋·태그 자동 실행 — `git-workflow.md`의 "커밋·푸시는 사용자가 요청할 때"를 따른다.
- 루트 `CHANGELOG.md` 승격 — 현행 2단 구조(내부 상세 + README 요약)를 유지한다.

## 요구사항 연결

이 레포의 `.claude/docs/01-*.md`는 **대상 프로젝트용 골격**(플레이스홀더 상태)이므로 REQ/FR를
발번하지 않는다. 추적은 `BACKLOG-002`(`.claude/workspace/todo.md`)와 `DEC-011`로 한다.
대상 프로젝트에 적용될 때는 각 프로젝트가 자체 REQ/FR로 연결한다.

## 설계

### 모듈 경계

```
scripts/lib-version.sh          신규 · 순수 조회 함수만 (부작용·출력 없음)
scripts/check-docs.sh           §5 changelog 스테일 · §6 버전 3자 일치 추가
scripts/new-release.sh          신규 · bump + 마감 + 골격 삽입 (git 부작용 없음)
scripts/test-check-docs.sh      §5·§6 회귀 케이스 추가
.claude/commands/release.md     신규 슬래시 커맨드
```

**진입점은 `check-docs.sh` 하나로 유지한다.** "check-docs 통과"라는 문구가 `settings.json`·
CI yml·`commands.md`·`validation.md`·README·`CLAUDE.md` 6곳에 박혀 있어, 진입점을 쪼개면 배선을
전부 고쳐야 하고 하나를 빼먹고 안 돌릴 위험이 생긴다.

lib은 값을 **반환만** 하고 경고 문구는 호출자가 만든다. 그래야 회귀 테스트에서 감지 로직만
따로 단언할 수 있다.

### `lib-version.sh` 인터페이스

| 함수 | 반환 |
|------|------|
| `detect_version_sot()` | `package.json:0.3.1` / `VERSION:0.3.1` / 빈 문자열 |
| `read_version_policy()` | `semver` / `calver` / `none` (선언 없으면 `semver`) |
| `changelog_latest_release()` | changelog 최신 릴리즈 헤딩의 버전 / 빈 문자열 |
| `latest_git_tag()` | 최신 `v` 접두 태그의 버전 / 빈 문자열 |
| `commits_since_changelog()` | changelog 마지막 수정 이후 feat/fix 커밋 수 (정수) |

### 버전 SoT 자동 감지 (우선순위)

```
1) package.json    → .version
2) pyproject.toml  → [project] version
3) Cargo.toml      → [package] version
4) VERSION (루트)  → 첫 줄
→ 하나도 없으면 버전 검사(§6) 자체를 건너뛴다
```

언어 매니페스트가 있으면 그것이 SoT다. 별도 버전 파일을 함께 두면 매니페스트와 이중 관리가 되어
드리프트하는데, 그건 이 harness가 없애려는 문제 그 자체다.

### 정책 선언 (자동 감지 override)

기본은 위 자동 감지다. 예외만 `.claude/rules/commands.md`에 한 줄로 선언한다.

```markdown
## 버전 정책
version-policy: semver
```

`none`은 §6을 끈다(매니페스트에 version이 형식상 박혀 있으나 실제로는 릴리즈를 안 끊는
private 내부 서비스용). `calver`는 §6의 semver 형식 검사만 끄고, `/release`가
`major|minor|patch` 대신 명시 버전 인자를 요구한다.

### §5 changelog 스테일 검사

```
기준점 = git log -1 --format=%H -- .claude/workspace/changelog.md
카운트 = 기준점 이후 커밋 중 subject가 feat/fix 타입인 것
3건 이상 → 경고
```

- **`feat`/`fix`만 센다.** `docs`·`chore`·`refactor`·`test`는 `readme-sync.md`의 갱신 트리거
  표에서도 제외 대상이라 일치시켰다. `perf`는 사용자 영향이 애매해 제외한다.
- **`[Unreleased]`가 비었는지는 보지 않는다.** 릴리즈 직후에는 정상적으로 비어 있어서, 그걸
  신호로 쓰면 매 릴리즈마다 오탐이 난다. 신호는 "파일이 커밋에서 수정됐는가" 하나다.
- **유예 3건**: 작업 중 연속 커밋에는 숨 쉴 틈을 주면서, 이 레포가 빠졌던 패턴(기능 커밋
  누적 · 갱신 0회)은 확실히 잡는 임계값이다.
- **git 레포가 아니거나 shallow clone이면 조용히 건너뛴다** — 경고가 아니라 스킵.
  `actions/checkout@v4`는 기본 depth 1이므로 CI에 `fetch-depth: 0`을 넣어 실제로 돌게 한다.

### §6 버전 3자 일치 검사

정책이 `none`이 아니고 SoT가 있을 때만 돈다.

| 상태 | 판정 |
|------|------|
| SoT ≠ changelog 최신 릴리즈 | 경고 — 둘은 `/release`가 동시에 쓰므로 항상 같아야 함 |
| 최신 tag > SoT | 경고 — 명백한 역전 |
| tag 없음 / tag < SoT | 안내만 — `/release` 직후 커밋·태그 전의 정상 상태 |
| SoT가 semver 형식이 아님 (정책 semver) | 경고 |

**태그 미달성은 안내, 역전만 경고**라는 비대칭이 핵심이다. `/release`가 파일만 고치고 태그는
사람이 달기 때문에, 그 사이 구간을 경고로 만들면 릴리즈할 때마다 빨간불이 뜬다.

### `new-release.sh` — 쓰기 후 재검증

```
$ bash scripts/new-release.sh minor

1. SoT 감지 → 현재 0.2.3
2. 다음 버전 계산 → 0.3.0
3. SoT 기록
     VERSION          → 직접 기록
     package.json     → npm version --no-git-tag-version (npm 있으면), 없으면 sed
     pyproject/Cargo  → 해당 섹션의 version 항목 치환
4. 재검증: detect_version_sot() 재호출 → 기대값 아니면 즉시 실패
5. changelog: Unreleased 섹션을 릴리즈 헤딩으로 마감, 위에 새 빈 Unreleased 삽입
6. README Changelog에 릴리즈 골격 삽입
7. 커밋·태그 명령어를 출력만 (실행하지 않음)
```

4번이 설계의 안전장치다. `pyproject.toml`·`Cargo.toml` 치환은 sed라 본질적으로 취약한데,
**쓴 뒤 감지 함수로 다시 읽어 기대값과 대조**하면 조용히 망가지는 경우가 사라진다. 틀리면
시끄럽게 죽는다.

6번의 골격에는 한글 대괄호 플레이스홀더를 넣는다. 그러면 **check-docs §1(플레이스홀더 잔존)이
README에서 이걸 자동으로 잡아**, 요약을 안 채우면 strict CI가 릴리즈 커밋을 막는다. 새 코드
없이 기존 장치를 재사용하는 지점이다.

> 알려진 갭: 스캐폴드 레포 자신은 `_skeleton-README.md` 자기감지로 §1이 꺼져 있어 이 시너지가
> 걸리지 않는다. 기존에 이미 감수한 갭이며 이번 작업에서 바꾸지 않는다.

`new-dec.sh`와 같은 관용구다 — 스크립트는 골격만 만들고, 판단이 필요한 내용(README 요약 항목
선별)은 에이전트가 채운다.

### 도그푸딩 — 이 레포에 적용

| 대상 | 내용 |
|------|------|
| `VERSION` | `0.1.0` 신규 |
| `workspace/changelog.md` | 골격 → 기존 커밋 6건 백필 + `v0.1.0` 마감. `todo.md`처럼 "대상 프로젝트는 비우고 시작" 주의문 추가 |
| `README.md` | 버전 표기 + Changelog + 파일 semantics 표 + 적용 체크리스트 |
| `git tag v0.1.0` | 사용자 확인 후 |

백필은 기존 커밋(`cd1493f`~`691e1a6`)을 근거로 쓴다 — 추측으로 만들지 않는다.
스캐폴드에 버전이 생기면 대상 프로젝트가 "scaffold v0.1.0 기준으로 적용"을 DEC에 기록할 수
있어 `BACKLOG-001`(글로벌 룰 버전 관리)과도 이어진다.

## 검토한 대안

`DEC-011`에 기록. 요약:

- **버전 SoT** — 채택: 매니페스트 우선 + 폴백 / 기각: 항상 별도 버전 파일(이중 관리) /
  기각: `.claude/version.json`(배포 툴체인이 못 읽음).
- **정책 판단** — 채택: 자동 감지 + 한 줄 override / 기각: 순수 자동(끄는 방법 없음) /
  기각: 명시 선언 필수(복사 직후 경고).
- **스테일 판정** — 채택: git 히스토리 + 유예 3 / 기각: 유예 없음(중간 커밋마다 경고) /
  기각: diff 기반(로컬·CI 동작 경로 2개).
- **`/release` 범위** — 채택: 파일 변경까지만 / 기각: 커밋+태그 자동(되돌리기 어려움, 룰 충돌) /
  기각: 2단계 finalize(누락 시 반준비 상태).
- **코드 경계** — 채택: lib 공유 + 검사는 check-docs 인라인 / 기각: 별도 진입점(배선 6곳 수정,
  빼먹을 위험) / 기각: lib 없이 복붙(감지 로직 드리프트).

## 리스크 / 고려사항

| 리스크 | 대응 |
|--------|------|
| `actions/checkout@v4` 기본 shallow clone에서 §5가 무력화 | CI에 `fetch-depth: 0` 추가. 스크립트는 shallow를 감지해 조용히 스킵 |
| `pyproject.toml`·`Cargo.toml` sed 치환 실패 | 쓰기 후 재검증(4단계) — 실패 시 즉시 종료 |
| §5가 커밋 타입 표기에 의존 (타입 오타 시 미검출) | 감수. 타입 표기는 `conventions.md`가 이미 규정하며, 게이트의 목적은 실수 방지지 우회 봉쇄가 아님 |
| `check-docs.sh`가 약 100줄에서 150줄로 증가 | 감수. 더 커지면 별도 진입점으로 분리하되 lib은 그대로 재사용 |
| 임시 git 레포를 만드는 회귀 테스트가 CI 환경 설정에 의존 | `git -c user.email=... -c user.name=...`로 전역 설정 비의존 |

## 완료 조건

> 구현 결과 섹션 번호가 §4→§5, §5→§6으로 밀렸다 — 선행 작업(DEC-012)이 DEC 댕글링 검사를
> §4로 신설했기 때문이다. 아래는 실제 구현 기준으로 기록한다.

- [x] `lib-version.sh` 5개 함수 구현, 매니페스트 4종 감지 동작
- [x] `check-docs.sh` §5·§6 추가, 기존 §1~§4 회귀 없음
- [x] `new-release.sh` 구현, 쓰기 후 재검증 포함, git 부작용 없음
- [x] `.claude/commands/release.md` 추가
- [x] `test-check-docs.sh`에 9개 케이스 추가 및 전체 통과
- [x] CI에 `fetch-depth: 0` · `settings.json`에 권한 추가
- [x] 룰 3종(`commands.md`·`readme-sync.md`·`project-init.md`) + `CLAUDE.md` 갱신
- [x] 도그푸딩: `VERSION` 0.1.0 · changelog 백필 6건 · README 반영
- [x] `DEC-011` 채움, `todo.md`에 `BACKLOG-002` 등록
- [x] `bash scripts/check-docs.sh --strict` 통과
