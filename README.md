# claude-project-scaffold

**v0.2.0** — 버전은 루트 `VERSION` 파일이 정본이며 `/release`로 끊습니다. 파생 프로젝트는
`.claude/SCAFFOLD-VERSION`에 받아온 버전이 찍혀 있으니 이 값과 비교하십시오
(→ [§스캐폴드 갱신 확인](#스캐폴드-갱신-확인-파생-프로젝트에서)).

> 코딩 에이전트(Claude Code 등)가 신규/기존 프로젝트에 **일관된 개발 방법론**을 부트스트랩하기 위한
> 재사용 스캐폴드 레포. 결정 추적 · 요구사항 관리 · 문서 동기화 · UI 목업 게이트가 처음부터
> 폴더 구조로 들어가 있습니다.
>
> **이 README는 사람 개발자와 이 스캐폴드를 적용하는 코딩 에이전트 양쪽을 독자로 삼습니다.**
> 지시는 명령형이며, 분기·검증 지점을 명시합니다.

---

## 이 레포의 정체 — 스캐폴드 + 얕은 harness

이 레포는 **스캐폴드**(복사해서 시작하는 정적 구조물)이면서, 그 위에 **얕은 harness**
(실제로 실행·강제되는 얇은 자동화 층)를 얹은 하이브리드입니다. 둘의 차이를 구분해야
어느 부분이 "권고"이고 어느 부분이 "강제"인지 알 수 있습니다.

| 구분 | 정의 | 이 레포에서 | 성격 |
|------|------|-------------|------|
| **스캐폴드(대부분)** | 복사해서 읽는 구조·문서·룰. 부트스트랩 한 번에 가치 실현 | `.claude/rules/*`, 요구사항·결정·아키텍처 문서 골격, spec/plan 템플릿 | **권고** — 컨텍스트에 로드되는 프롬프트. 에이전트의 성실성에 의존 |
| **얕은 harness(척추)** | 런타임에 실제로 실행·검사·차단하는 장치 | `scripts/check-docs.sh`, Stop hook, 슬래시 커맨드(`/dec`·`/new-feature`·`/release`), CI | **강제** — 저비용·고신뢰 불변식만 기계로 못 박음 |

**설계 철학**: 강제는 *저비용·고신뢰 불변식*(DEC 번호 충돌·플레이스홀더 잔존·댕글링 참조)에만
걸고, *판단이 필요한 게이트*(목업 승인·brainstorming 우선)는 권고로 둡니다. 하드 차단을 남발하면
빠르게 움직일 때 거슬리고 이질적 프로젝트에서 취약해지기 때문입니다. 로컬 hook은 **비차단(경고)**,
원격 CI는 **차단(strict)** — 로컬은 부드럽게, 병합 지점은 엄격하게.

**사람 개발자에게**: 방법론 구조 + 가벼운 자동화를 얻되, 경직된 우리(cage)에 갇히지는 않습니다.
`scripts/check-docs.sh`로 문서 정합성을 언제든 스스로 점검하고, `/dec`·`/new-feature`로
반복 작업을 결정론적으로 처리합니다.

**코딩 에이전트에게**: `.claude/rules/*`는 따라야 할 규범이지만 위반해도 도구가 막지는
않습니다(권고). 반면 check-docs·hook·CI·슬래시 커맨드는 실제로 실행되는 강제 장치입니다 —
특히 DEC 번호 할당·문서 정합성은 손으로 하지 말고 **harness 동사(슬래시 커맨드)**를 쓰십시오.

> harness의 나머지(강한 PreToolUse 차단, 테스트 출력 파싱→상태 자동화, statusline)는
> 의도적으로 넣지 않았습니다. 특정 프로젝트에서 실제로 아쉬울 때 그 프로젝트에서만 추가하십시오.

---

## 에이전트 실행 요약 (먼저 읽기)

당신은 이 스캐폴드를 **대상 프로젝트**에 적용하는 코딩 에이전트입니다. 다음 순서로 실행합니다.

1. **판별** — 대상이 greenfield(빈/신규)인지 brownfield(기존 코드·git 이력 존재)인지 결정한다. → [§적용 절차](#적용-절차)
2. **분기 실행** — 판별 결과에 해당하는 **절차 하나만** 실행한다. 다른 절차는 무시한다.
   - greenfield → [§A. greenfield 절차](#a-greenfield-빈신규-폴더-통째-복사)
   - brownfield → [§B. brownfield 절차](#b-brownfield-기존-선별-병합) — ⚠️ **통째 복사(`cp -r`) 금지**
3. **치환** — `[프로젝트명]`·`[개요]`·`[스택/호환버전]`·`YYYY-MM-DD` 등 플레이스홀더를 실제 값으로 채운다.
4. **검증** — [§적용 완료 체크리스트](#적용-완료-체크리스트)로 자체 확인한다.
5. **이후 모든 작업** — [§작업 사이클 게이트](#작업-사이클-게이트-매-작업-동일)를 매 작업마다 따른다.

> 이 스캐폴드는 **자체 완결형**입니다. `.claude/CLAUDE.md`가 로컬 룰을 `@import`하므로
> 글로벌 룰(`~/.claude`) 없이 복사만으로 동작합니다.

---

## 전제 조건 (Prerequisites)

- **superpowers 스킬 설치 (권장 전제)** — 이 스캐폴드의 작업 사이클 게이트는
  superpowers 스킬(`brainstorming`, `writing-plans`, `systematic-debugging`,
  `test-driven-development` 등)이 에이전트 환경에 설치돼 있다고 **가정**합니다.
  spec/plan 산출물 경로(`docs/superpowers/`)와 룰(`.claude/rules/*`)이 이 스킬들을 전제로 작성돼 있습니다.
- **없어도 동작(graceful degrade)** — 스킬이 없으면 자동 호출은 안 되지만,
  `.claude/rules/`에 절차가 글로 명시돼 있어 에이전트가 **수동으로 동일 게이트**를 따를 수 있습니다.
  단, 이 경우 스킬이 주는 강제력·일관성은 약해집니다.
- **frontend-design 스킬 (선택 · UI 작업 한정)** — UI 목업 게이트(②)에서 디자인 품질이
  중요한 경우 사용을 가정합니다. 없어도 순수 HTML 목업으로 게이트는 동작하며,
  UI가 없는 프로젝트에는 무관합니다.

---

## 적용 유형 판별 — 두 축으로 본다

단일 greenfield/brownfield 2분류는 **"기획 문서는 있는데 코드는 0줄"** 인 프로젝트를 담지
못한다. 그런 프로젝트는 `README.md` 존재만으로 brownfield로 판정되지만, brownfield의 가장 큰
비용인 ③ 역설계는 **역설계할 코드가 없어 통째로 무의미**하다. 반대로 "기존 README는 유지"라는
지침은 그 README가 문서 체계 자체의 정의서일 때 정면으로 틀린다.

그래서 **두 축을 따로 본다.**

```
축 1 — 코드: 소스 파일이 있는가?       → ③ 역설계 필요 여부를 결정
축 2 — 문서: 기존 문서 규약이 있는가?  → ⓪ 경로 충돌 조정 필요 여부를 결정
        (CLAUDE.md · README · docs/ 규약 · 결정 로그 · todo 체계 등)
```

| 코드 | 문서 | 유형 | 적용 절차 |
|:---:|:---:|------|-----------|
| ✗ | ✗ | **순수 greenfield** | §A 통째 복사 |
| ✗ | ✓ | **문서 선행형** | §B의 **⓪ 필수**, ③ 역설계 생략 — 요구사항·아키텍처는 기획 문서에서 도출(greenfield식) |
| ✓ | ✗ | **코드 선행형** | §B의 ③ 역설계 필수, ⓪ 불필요 |
| ✓ | ✓ | **완전 brownfield** | §B 전체 |

> **"문서 선행형"은 드문 케이스가 아니다** — 기획서를 먼저 쓰고 에이전트로 구현하는 워크플로에서
> 오히려 표준에 가깝고, 이 스캐폴드가 겨냥하는 사용자층과 정확히 겹친다.

확신이 서지 않으면 사용자에게 확인한다. **오판 시 위험이 큰 쪽은 문서 축** — 코드 충돌은 즉시
드러나지만 문서 정본 충돌은 조용히 오래 간다(→ §B ⓪).

---

## 방법론 7대 구성요소

| # | 구성요소 | 핵심 규칙 | 관련 파일 |
|---|----------|-----------|-----------|
| ① | superpowers 산출물 ↔ `.claude/` 통합 흐름 | spec/plan ↔ 결정·요구사항·현황을 단일 흐름으로 연결 | `.claude/rules/project-init.md`, `docs/superpowers/` |
| ② | HTML 목업 우선(UI 설계 게이트) | 목업 검토·승인 없이 UI 코드 작성 금지 | `.claude/rules/ui-mockups.md` |
| ③ | 의사결정 자동 로깅 | 선택+기각 대안 보존, append-only | `.claude/rules/decisions.md`, `.claude/decisions/` |
| ④ | 구현 현황 트래킹 + 자동 갱신 | 단계 완료 시 현황표·todo 자동 갱신 | `.claude/rules/requirements.md`, `.claude/docs/01-impl-requirements.md`, `.claude/workspace/todo.md` |
| ⑤ | 요구사항 2분할 | 구현 관점(REQ-N-M) / 사용자 관점(FR-NN) | `.claude/docs/01-impl-requirements.md`, `.claude/docs/01-user-requirements.md` |
| ⑥ | 사용자 가이드 — 실제 구현 근거 작성 | 추측 금지, 코드 확인 후 갱신 | `.claude/rules/readme-sync.md`, `docs/user-guide.md` |
| ⑦ | 버전 관리 + 외부 의존성 호환 버전 명시 | 릴리즈는 `/release`로 끊고(버전 SoT·changelog·README 동시 갱신), 의존성은 호환 버전을 근거(DEC)와 함께 고정 | `.claude/rules/readme-sync.md` §릴리즈 절차, `.claude/rules/commands.md` §버전 정책, `.claude/rules/conventions.md` |

---

## 디렉토리 구조 & 파일 semantics

에이전트가 각 파일을 **언제 읽고/쓰는지** 알 수 있도록 역할을 명시합니다. 대부분 골격
(플레이스홀더 포함)으로 제공되며, 적용 시 실제 내용으로 채웁니다.

```
claude-project-scaffold/
├── README.md                       ← (이 파일) 에이전트용 적용 안내. greenfield에선 삭제/교체 대상
├── _skeleton-README.md             ← 대상 프로젝트가 README.md로 복사해 채우는 스켈레톤
├── .gitignore
├── .github/workflows/
│   └── check-docs.yml              ← CI: push/PR에서 check-docs --strict (차단 게이트)
├── scripts/
│   ├── check-docs.sh               ← 문서 정합성 검사(플레이스홀더·필수문서·REQ/FR·DEC·changelog·버전·BACKLOG·README버전·스탬프)
│   ├── lib-version.sh              ← 버전·changelog 조회 함수(check-docs·new-release 공유)
│   ├── new-release.sh              ← 릴리즈 끊기 (/release 가 호출)
│   ├── test-check-docs.sh          ← check-docs 검출 로직 회귀 테스트(CI 실행)
│   ├── test-new-dec.sh             ← new-dec 번호 할당·말미 정규화 회귀 테스트(CI 실행)
│   ├── new-dec.sh                  ← DEC 번호 원자 할당 (/dec 가 호출)
│   └── new-feature.sh              ← spec/plan 골격 생성 (/new-feature 가 호출)
├── docs/
│   ├── user-guide.md               ← 사용자 가이드 골격(사람용 납품 문서 — 숨김 폴더 밖)
│   ├── how-it-works.md             ← 동작 원리 골격(트리거별 흐름, Mermaid — 사람용 납품 문서)
│   └── superpowers/
│       ├── specs/   _TEMPLATE-design.md   ← brainstorming 산출물 골격 (+ mockups/)
│       └── plans/   _TEMPLATE-plan.md     ← writing-plans 산출물 골격
└── .claude/
    ├── CLAUDE.md                   ← 200줄 이하 + @import (방법론 룰 9종 + commands)
    ├── settings.json               ← 팀 공유 설정 + Stop hook(비차단 check-docs)
    ├── commands/                   ← 슬래시 커맨드 /dec · /new-feature · /release (harness 동사)
    ├── rules/                      ← 방법론 룰 9종 + commands.md(프로젝트 명령어)
    ├── decisions/                  ← 결정 로그 + ADR 템플릿 (append-only 누적)
    ├── docs/                       ← 요구사항(2종) + 아키텍처 (영구)
    └── workspace/                  ← 진행 현황판 + 내부 changelog (실시간 갱신)
```

### `.claude/` — 누적·영구 산출물

| 파일 | 에이전트 관점 역할 |
|------|--------------------|
| `SCAFFOLD-VERSION` | 이 프로젝트가 **받아온 스캐폴드 버전** 한 줄. 업스트림과 비교해 갱신 여부를 판단한다(→ 아래 "스캐폴드 갱신 확인") |
| `CLAUDE.md` | 세션 시작 시 자동 로드. 핵심 요약 + 룰 `@import` + 산출물 흐름도. **200줄 이하** 유지 |
| `settings.json` | 팀 공유 설정. `check-docs.sh` 실행 허용 포함. Stop hook 연결은 opt-in(→ `rules/commands.md`) |
| `rules/project-init.md` | ① 디렉토리 구조·역할 구분(누적 vs 작업단위)·brownfield 주의·부트스트랩 |
| `rules/planning.md` | 워크플로 게이트(brainstorming→plan→구현→갱신), spec/plan 머리말 규칙 |
| `rules/requirements.md` | ④⑤ 요구사항 2분할(REQ/FR)·구현 현황 요약 표·자동 갱신 규칙 |
| `rules/decisions.md` | ③ DEC 자동 로깅 형식·append-only·ADR 관계·의존성 버전 근거 |
| `rules/ui-mockups.md` | ② HTML 목업 우선 게이트(목업 없이 UI 코드 금지) 절차 |
| `rules/validation.md` | 빌드→단위→통합→타입/린트→수동 검증 순서, "테스트 없으면 미완료" |
| `rules/conventions.md` | 네이밍·커밋·주석 규칙 + ⑦ 버전 메타데이터·의존성 고정 |
| `rules/git-workflow.md` | 위험도 기반 브랜치 전략(메인 직접 vs 브랜치+PR), PR=게이트, 브랜치 네이밍 |
| `rules/readme-sync.md` | ⑥ README/사용자 가이드 자동 동기화, **갱신 묶음 단일 정본**, 릴리즈 절차 |
| `rules/commands.md` | 프로젝트 명령어(빌드·테스트·check-docs). 방법론 룰이 아닌 프로젝트 고유 정보 |
| `decisions/decision-log.md` | 모든 결정 누적 로그(DEC-NNN). 스캐폴드 자체 결정 이력이 형식 예시 겸으로 포함 — **적용 시 비우고 시작**. **append-only** |
| `decisions/ADR-000-template.md` | 큰 아키텍처 결정용 ADR 템플릿(맥락/결정/대안/결과) |
| `docs/01-impl-requirements.md` | ⑤ 구현 관점 요구사항(REQ-N-M) + 구현 현황 요약 표(SoT) |
| `docs/01-user-requirements.md` | ⑤ 사용자 관점 기능 요구사항(FR-NN, 체크박스) |
| `docs/02-architecture.md` | 아키텍처 스냅샷. greenfield는 첫 구조 확정 시, brownfield는 도입 시 역설계로 작성 |
| `workspace/todo.md` | ④ 실시간 현황판(🔄 진행/✅ 완료/⏳ 대기/🚧 블로커) + BACKLOG 표(상태·근거, check-docs §7이 검사) |
| `workspace/changelog.md` | 내부 상세 기술 이력(외부 요약은 대상 README의 Changelog) |

### `docs/` — 사람용 납품 문서 + 작업 단위 산출물

| 파일 | 에이전트 관점 역할 |
|------|--------------------|
| `user-guide.md` | ⑥ 사용자 가이드 골격(사람용 납품 문서). 실제 구현 근거로 작성·갱신 |
| `how-it-works.md` | 동작 원리 골격(사람용 납품 문서). 큰 기능·트리거별 컴포넌트 흐름(Mermaid). **동적 흐름** — architecture(정적 구조)와 상보 |
| `superpowers/specs/_TEMPLATE-design.md` | brainstorming 설계 정본 골격. **복사**해서 `YYYY-MM-DD-*-design.md` 생성 |
| `superpowers/specs/mockups/` | ② UI 목업(.html) 저장 위치 |
| `superpowers/plans/_TEMPLATE-plan.md` | writing-plans 작업 분해 골격. **복사**해서 `YYYY-MM-DD-*.md` 생성 |

> `_TEMPLATE-*.md`는 **삭제하지 않는다** — 매 작업마다 복사 원본으로 재사용한다.

### `scripts/`·`.claude/commands/`·`.github/` — 얕은 harness 척추

| 파일 | 역할 | 성격 |
|------|------|------|
| `scripts/check-docs.sh` | 플레이스홀더 잔존(비-ASCII 대괄호·VAR_NAME·날짜·ID 리터럴 — 코드펜스 전체 제외, ID 리터럴은 인라인 코드도 제외)·REQ/FR 댕글링 참조·DEC 번호·DEC 댕글링 참조 검사. 템플릿 자기감지(`_skeleton-README.md`)로 스캐폴드 자신은 플레이스홀더 검사 생략 | 강제(경고/strict) |
| `scripts/test-check-docs.sh` | check-docs 검출 로직 회귀 테스트(정탐·오탐·펜스/백틱 제외·DEC 댕글링·복사 직후 상태·strict 종료코드). CI에서 실행 | 강제(테스트) |
| `scripts/test-new-dec.sh` | new-dec 회귀 테스트(번호 할당·말미 정규화·접합 방지). CI에서 실행 | 강제(테스트) |
| `scripts/new-dec.sh` | 다음 DEC 번호 **원자 할당** + 골격 append (병렬 세션 충돌 예방). append 전 말미를 정규화해 로그를 비운 상태에서도 접합되지 않음 | 강제(결정론) |
| `scripts/new-feature.sh` | 오늘 날짜로 spec/plan 골격 생성 | 강제(결정론) |
| `scripts/lib-version.sh` | 버전 SoT 감지·정책 조회·changelog/tag 조회. **순수 조회 전용**(쓰기·경고 없음) — check-docs와 new-release가 공유 | 공유 라이브러리 |
| `scripts/new-release.sh` | 버전 bump(쓰기 후 재검증) + changelog 마감 + README 골격 삽입. git 부작용 없음 | 강제(결정론) |
| `.claude/commands/dec.md` | `/dec <제목>` — new-dec.sh 호출 후 결정 내용 작성 안내 | harness 동사 |
| `.claude/commands/new-feature.md` | `/new-feature <slug>` — new-feature.sh 호출 후 brainstorming 게이트 안내 | harness 동사 |
| `.claude/commands/release.md` | `/release <bump>` — new-release.sh 호출 후 README 요약 이관·납품물 확인 안내 | harness 동사 |
| `.github/workflows/check-docs.yml` | push/PR에서 `check-docs.sh --strict` 실행 — 병합 지점 차단 게이트 | 강제(차단) |

> **로컬은 부드럽게, 병합 지점은 엄격하게**: Stop hook은 비차단(경고), CI는 차단(strict)이다(DEC-006).

---

## 적용 절차

### A. greenfield (빈/신규) — 폴더 통째 복사

빈 프로젝트라 충돌이 없으므로 전체 구조를 그대로 가져온다.

```
1. 이 폴더 전체를 대상 프로젝트 위치로 복사한다.
   - git 새로 시작: rm -rf .git && git init
2. 플레이스홀더([프로젝트명]·[개요]·[스택/호환버전]·YYYY-MM-DD)를 실제 값으로 치환한다.
   - 대상: .claude/CLAUDE.md, .claude/docs/*, .claude/workspace/*, .claude/rules/commands.md,
     docs/user-guide.md, _skeleton-README.md
3. .claude/decisions/decision-log.md 의 기존 DEC 항목(스캐폴드 자체 결정 이력)을 비우고,
   대상 프로젝트의 DEC-001부터 새로 시작한다.
4. _skeleton-README.md 를 README.md 로 복사해 채운다(이 스캐폴드 소개 README는 덮어쓴다).
5. .claude/CLAUDE.md 를 루트 CLAUDE.md로 쓸지 결정한다(루트에 있으면 에이전트가 자동 로드).
6. _TEMPLATE-*.md(spec/plan 템플릿)는 남겨 두고, 실제 작업은 복사해서 만든다.
7. 불필요한 안내 파일(이 README, _skeleton-README.md 등)을 정리한다.
8. 치환 완료를 `bash scripts/check-docs.sh` 로 확인한다(플레이스홀더 잔존 검사).
9. 첫 작업은 brainstorming → spec 으로 시작한다(코딩 먼저 금지).
   첫 구조가 잡히면 .claude/docs/02-architecture.md 를 채운다.
```

### B. brownfield (기존) — 선별 병합

이미 코드·`CLAUDE.md`·`README`·git 이력이 있으므로 **통째 복사 금지**.
룰 자체는 이미 brownfield 우선 원칙을 따른다(`rules/project-init.md` Brownfield 주의사항,
`rules/conventions.md` 참조). 바뀌는 건 룰이 아니라 도입 절차뿐이다.

> ⚠️ **핵심 함정 2개**
> 1. `cp -r`로 통째 덮어쓰면 기존 `CLAUDE.md`·`README.md`가 **사라진다**.
> 2. 그보다 **발견하기 어렵고 더 오래 아픈 것** — 이미 문서 규약이 있는 프로젝트에 복사하면
>    파일은 하나도 안 사라지는데 **같은 역할에 정본이 둘**이 되어, 세션마다 어느 쪽을 읽을지
>    갈린다. 아무도 눈치채지 못한다. → 아래 ⓪을 먼저 한다.

**⓪ 경로 충돌 조정** (①보다 **먼저** — 문서 축이 ✓일 때 필수)

기존 프로젝트가 아래 역할에 **이미 정본 경로를 갖고 있는지** 확인한다. 갖고 있다면 **복사 전에**
어느 쪽이 정본인지 정하고 `DEC`로 남긴다.

| 역할 | 스캐폴드 경로 | harness가 하드코딩? |
|------|---------------|---------------------|
| 결정 로그 | `.claude/decisions/decision-log.md` | ✅ `new-dec.sh`·`check-docs.sh` |
| 요구사항 | `.claude/docs/01-*-requirements.md` | ✅ `check-docs.sh` 상호 참조 검사 |
| 아키텍처 | `.claude/docs/02-architecture.md` | ✅ `check-docs.sh` 플레이스홀더 |
| 진행 현황 | `.claude/workspace/todo.md` | ✅ `check-docs.sh` 플레이스홀더 |
| 변경 이력 | `.claude/workspace/changelog.md` | ✅ `check-docs.sh` 스테일 검사·`new-release.sh` |
| 버전 SoT | 매니페스트 우선, 없으면 루트 `VERSION` | ✅ `lib-version.sh` 자동 감지 |

**판정 기준**: 기본적으로 **harness가 하드코딩한 경로를 정본으로 삼는 편이 유리하다** — 기계
검사를 그대로 받고, 상류(스캐폴드) 갱신 시 재작업이 없다. 기존 경로를 정본으로 유지해야 한다면
**스크립트를 포크해야 함**을 인지하고 결정한다.

**예외를 두는 게 맞는 경우**: 기존 경로가 **다른 도구·프로토콜의 기반**일 때. 예를 들어 다중
세션 조율을 위해 owner/deps/크리티컬 패스 구조의 `todo` SSOT를 이미 쓰고 있다면, 스캐폴드
현황판(🔄/✅/⏳/🚧 + BACKLOG 표)은 형태가 달라 병합이 불가능하다. 이때는 기존 쪽을 SSOT로 두고
`workspace/todo.md`는 "인플라이트 보드(SSOT 아님)"로 격하하는 판정이 맞다 — **어느 쪽이든 DEC로
명시하는 것이 핵심**이다. 정하지 않고 넘어가는 것만이 오답이다.

**① 그대로 복사해도 안전** (순수 방법론, 기존 코드 무영향)

> ⓪을 마친 뒤에 수행한다. 아래 "안전"은 **코드에 무영향**이라는 뜻이지 문서 체계에 무영향이라는
> 뜻이 아니다.

| 대상 | 이유 |
|------|------|
| `.claude/rules/` 방법론 9종 + `commands.md` | 프로젝트 무관한 작업 방식(commands는 골격만 복사 후 실제 명령어로 채움) |
| `.claude/decisions/` | 로그를 비우고(스캐폴드 자체 DEC 제거) **지금부터** 누적 시작 |
| `.claude/workspace/` | 현재 진행 현황을 스냅샷으로 채움 |
| `.claude/commands/` | 슬래시 커맨드(/dec·/new-feature). 코드 무영향 |
| `scripts/` (check-docs·new-dec·new-feature) | 정합성 검사·harness 동사. 코드 무영향 |
| `.github/workflows/check-docs.yml` | CI 정합성 게이트(기존 워크플로가 있으면 병합) |
| `docs/superpowers/specs\|plans/` 템플릿 | 다음 작업부터 사용 |

**② 덮어쓰지 말고 "병합"** ⚠️

| 대상 | 처리 |
|------|------|
| `CLAUDE.md` | 기존 내용 보존 + 스캐폴드의 `@import`·산출물 흐름만 **추가 병합**(overwrite 금지) |
| `README.md` | 스캐폴드 소개용 README는 불필요. 기존 README는 **원칙적으로 유지**하되, 그 README가 **문서 체계 자체의 정의서**라면(경로·규약을 규정) ⓪의 판정 결과에 맞춰 상당한 재작성이 필요할 수 있다 — "유지"로 넘기지 말고 확인한다 |
| `.gitignore` | 누락된 줄(`settings.local.json` 등)만 append |
| `.claude/settings.json` | 이미 있으면 병합 |
| `_skeleton-README.md` | 이미 README가 있으니 **삭제** |

**③ 역설계(retroactive), 점진적으로** — **코드 축이 ✓일 때만**

> 문서 선행형(코드 0줄)은 이 절을 **통째로 건너뛴다.** 역설계할 코드가 없다. 요구사항·아키텍처는
> "이미 만든 것을 거꾸로 문서화"가 아니라 **기획 문서에서 앞으로 만들 것을 도출**하는
> greenfield식 작업이다.

greenfield는 "앞으로 만들 것"을 적지만 코드가 있는 brownfield는 **이미 만든 것을 거꾸로
문서화**한다. 유일한 큰 비용이지만 한 번에 다 할 필요는 없다.

- **requirements(REQ/FR)**: 돌고 있는 앱·엔드포인트에서 추출. 처음엔 골격 + 핵심 기능 몇 개만, 이후 작업하며 증분 등록(100% 선행 금지).
- **architecture**: 현재 코드 구조를 한 번 훑어 `.claude/docs/02-architecture.md` 골격을 채운다.
- **decision-log**: 과거 결정은 복구 불가 → **지금부터** 로깅 시작. 아직 살아있는 **큰** 과거 결정(스택 선택·핵심 의존성 버전 고정 등) 3~5개만 ADR로 선택 백필하면 추적성이 크게 향상.

**권장 도입 순서**

```
0. 경로 충돌 조정 — 역할 4종의 정본을 정하고 DEC로 남긴다  (문서 축 ✓일 때 필수, 복사 전)
1. rules/decisions/workspace/scripts/superpowers 복사      (코드 무영향)
2. CLAUDE.md 병합 (기존 보존 + @import·핵심원칙 추가)
3. 현재 진행 상황을 workspace/todo.md에 스냅샷
4. 02-architecture.md 작성
     코드 축 ✓ → 코드를 훑어 현재 상태를 기록
     코드 축 ✗ → 기획 문서에서 앞으로 만들 구조를 도출
5. requirements 골격 생성 → 핵심 기능부터 점진 채움
6. 살아있는 과거 큰 결정만 ADR 백필, 이후 DEC 즉시 로깅 시작  (코드 축 ✓일 때)
7. _skeleton-README.md 삭제. 기존 README는 유지하되 ⓪ 판정으로 규약이 바뀌었으면 반영
8. 첫 작업부터 brainstorming → spec 게이트 적용
```

---

## 작업 사이클 게이트 (매 작업 동일)

적용 이후 **모든 작업**은 다음 게이트를 순서대로 통과한다. 진입점으로 harness 동사를 쓴다.

0. `/new-feature <slug>` → spec/plan 골격이 오늘 날짜로 생성됨(수동: `bash scripts/new-feature.sh <slug>`)
1. **brainstorming** → `docs/superpowers/specs/YYYY-MM-DD-*-design.md` (UI 포함 시 **목업 게이트** 통과)
2. **writing-plans** → `docs/superpowers/plans/YYYY-MM-DD-*.md`, `.claude/workspace/todo.md`에 태스크 등록
3. 결정 발생 시 **즉시 DEC 로깅** — `/dec <제목>`(번호 원자 할당, 수동: `bash scripts/new-dec.sh`)
4. 구현 → 태스크별 리뷰 → 최종 리뷰
5. 완료 시 **자동 갱신 묶음**: 구현현황표 + todo + changelog + README + 사용자 가이드
6. 의존성 변경 시 **호환 버전 + 근거**를 DEC와 README Prerequisites에 기록

### 산출물 흐름 (단일 흐름)

```
아이디어
  └─ brainstorming → docs/superpowers/specs/YYYY-MM-DD-*-design.md   (설계 정본)
        └─ writing-plans → docs/superpowers/plans/YYYY-MM-DD-*.md     (작업 분해)
              └─ 구현 중 결정 → .claude/decisions/decision-log.md     (DEC-NNN)
              └─ 진행 현황   → .claude/workspace/todo.md              (BACKLOG/태스크)
              └─ 완료 시     → 구현현황표 + todo + changelog + README + 사용자 가이드
```

- `.claude/` = **누적·영구**(결정·요구사항·아키텍처), `docs/superpowers/` = **작업 단위 산출물**.
- spec/plan 머리말에 관련 `BACKLOG-NNN`·`DEC-NNN`·`REQ-NNN`·`FR-NN`을 상호 참조로 명시.

---

## 적용 완료 체크리스트

적용 절차 실행 후, 에이전트는 아래를 자체 확인한다.

```
공통
- [ ] .claude/CLAUDE.md 가 로드되고 방법론 룰 9종 + commands.md 를 @import 하는가
- [ ] 플레이스홀더([프로젝트명]·[개요]·[스택/호환버전])가 실제 값으로 치환됐는가
      → bash scripts/check-docs.sh 로 기계 확인
- [ ] .gitignore 에 settings.local.json·node_modules·dist 가 포함됐는가
- [ ] decision-log.md 를 비우고 대상 프로젝트의 DEC-001부터 시작하는가
- [ ] workspace/changelog.md 를 비우고 대상 프로젝트 이력으로 시작하는가
- [ ] 버전 SoT 가 의도한 것인가 — 매니페스트가 있으면 그쪽이 정본, 없으면 루트 VERSION.
      릴리즈를 끊지 않는 프로젝트면 commands.md 에 version-policy: none 을 선언했는가

greenfield 추가
- [ ] _skeleton-README.md 를 README.md 로 교체하고 스캐폴드 소개 README를 정리했는가
- [ ] _TEMPLATE-*.md(spec/plan)는 남겨 두었는가

문서 축 ✓ 추가 (문서 선행형 · 완전 brownfield)
- [ ] ⓪ 경로 충돌 조정을 복사 전에 수행했는가 — 역할 4종(결정 로그·요구사항·아키텍처·
      진행 현황)의 정본을 정하고 DEC로 남겼는가
- [ ] 기존 CLAUDE.md·README.md·.gitignore 를 덮어쓰지 않고 "병합"했는가
- [ ] _skeleton-README.md 를 삭제했는가
- [ ] 기존 README가 문서 체계 정의서였다면 ⓪ 판정 결과를 반영했는가

코드 축 ✓ 추가 (코드 선행형 · 완전 brownfield)
- [ ] requirements/architecture 골격을 만들고 핵심부터 점진 채우기를 시작했는가
- [ ] 살아있는 큰 과거 결정을 ADR로 선택 백필했는가

코드 축 ✗ 추가 (순수 greenfield · 문서 선행형)
- [ ] ③ 역설계를 건너뛰고, 요구사항·아키텍처를 기획 문서에서 도출했는가
```

---

## 스캐폴드 갱신 확인 (파생 프로젝트에서)

파생 프로젝트는 `.claude/SCAFFOLD-VERSION`에 **받아온 스캐폴드 버전**을 갖는다. 코드를 diff할
필요 없이 이 숫자와 업스트림을 비교하면 된다.

```bash
cat .claude/SCAFFOLD-VERSION                                   # 내가 받은 버전
curl -s https://raw.githubusercontent.com/ooosm/claude-project-scaffold/main/VERSION   # 업스트림 최신
```

- **다르면**: 업스트림 `README.md`의 Changelog에서 그 사이 버전들의 항목을 읽고, 필요한 변경만
  가져온다(전체 덮어쓰기는 brownfield 병합 규칙 §B를 따른다).
- 가져온 뒤 `.claude/SCAFFOLD-VERSION`을 **손으로** 그 버전으로 고친다. 파생 레포에서
  `/release`는 이 파일을 건드리지 않는다 — 스탬프는 "내 버전"이 아니라 "받아온 버전"이다.
- 상세 이력이 필요하면 업스트림 `.claude/workspace/changelog.md`를 본다(릴리즈 단위 요약은
  README Changelog).

> 스탬프가 없는 파생 프로젝트(v0.2.0 이전에 만든 것)는 값을 알 수 없다. 다음 동기화 때
> 그 시점의 버전을 적어 넣는 것으로 시작한다 — 소급 추정하지 않는다.

---

## 부록 — 방법론 패키징 방식 3종

이 방법론을 재사용 가능하게 **패키징하는 방식**은 셋이다. 이 레포는 그중 **스캐폴드 방식**을
구현한 것이고, 나머지 둘은 함께 쓰거나 대체할 수 있는 대안이다. (아래는 참고용 배경 정보 —
적용 절차는 위 §적용 절차만 따르면 된다.)

| 방식 | 무엇인가 | brownfield 적용 | 강점 | 약점 |
|------|----------|-----------------|------|------|
| **스캐폴드 (이 레포)** | 룰·문서·워크스페이스 골격 폴더를 복사해 시작 | ✅ **가능** — 룰+구조물을 실제 파일로 함께 가져와 선별 병합 | 이식성 높음, 팀·타 머신 공유 용이 | 룰 변경 시 템플릿 갱신·재배포 필요 |
| **대안 1 — 글로벌 룰 승격** | 룰을 `~/.claude/rules/`로 옮겨 모든 프로젝트가 자동 상속 | △ **부분** — 룰은 자동 적용, 구조물(문서·폴더)은 미생성 | 가장 강력, 신규 프로젝트에 자동 상속 | 머신·계정에 묶여 팀 공유·이식 어려움 |
| **대안 2 — 운영 문서(METHODOLOGY.md)** | 방법론을 단계별 게이트 체크리스트 한 문서로 정리 | △ **부분** — 체크리스트만 이식, 구조·강제력 없음 | 단일 문서로 즉시 검토·공유 | 강제력 약함, 폴더 구조 자동 생성 안 됨 |

> **brownfield 이식성**: 방법론은 **룰(작업 방식) + 구조물**(결정 로그·요구사항 문서·워크스페이스·
> superpowers 골격)로 이뤄지는데, 이 **둘을 '전체로서' 기존 프로젝트에 이식할 수 있는 건
> 스캐폴드 방식뿐**이다(룰과 구조물을 실제 파일로 함께 가져와 선별 병합).
> 대안 1은 구조물을 만들어 주지 않고, 대안 2는 구조 생성·강제력이 없다.

> 권장: **스캐폴드를 배포 수단으로, 대안 1을 자동 적용의 뼈대로, 대안 2를 운영 규칙 문서로**
> 함께 사용. 셋은 배타적이지 않다.

### 대안 1 — 글로벌 룰로 승격 (적용 방법 3단계)

이 레포의 `.claude/rules/` 룰들을 `~/.claude/rules/`로 옮기고 `~/.claude/CLAUDE.md`의
`@import` 목록에 등록하면, **모든 신규 프로젝트가 별도 복사 없이 룰을 자동 상속**한다.

1. **신규 3종 룰 복사** — `decisions.md`·`requirements.md`·`ui-mockups.md`를 `~/.claude/rules/`로 복사(충돌 없이 추가).
2. **기존 5종 룰은 "항목 보강"으로 병합** — `project-init`·`planning`·`validation`·`conventions`·`readme-sync`는 통째 교체하지 말고, 템플릿에만 있는 방법론 항목만 골라 기존 파일에 추가한다(예: `planning.md`→워크플로 게이트, `conventions.md`→의존성 호환 버전 고정, `readme-sync.md`→완료 시 자동 갱신 묶음). 충돌 시 정본 한쪽만 남긴다(중복 금지).
3. **`@import` 목록에 신규 3종 등록** — 프로세스 룰(planning·requirements·decisions·ui-mockups)을 구현·검증 룰(validation·conventions) **앞**에 둬 "먼저 생각하고 나중에 코딩" 흐름과 일치시킨다.

```
@~/.claude/rules/project-init.md
@~/.claude/rules/planning.md
@~/.claude/rules/requirements.md   ← 추가
@~/.claude/rules/decisions.md      ← 추가
@~/.claude/rules/ui-mockups.md     ← 추가
@~/.claude/rules/validation.md
@~/.claude/rules/conventions.md
@~/.claude/rules/readme-sync.md
```

**적용 확인**: 아무 프로젝트에서 새 세션을 열어 룰이 실제로 걸리는지 본다(대안 선택 시 DEC
로깅을 시도하는지, UI 작업에서 목업 게이트를 요구하는지).

> **글로벌 룰 버전 관리 (로드맵 · BACKLOG-001)**: 글로벌 룰(`~/.claude/rules/`)은 이 스캐폴드
> 레포에서 미러링되지만(정본 방향: 스캐폴드 → 글로벌, DEC-002), 현재 `~/.claude`는 어떤 git
> 레포에도 포함되지 않아 **변경 이력·롤백·머신 간 동기화가 불가**하다.
>
> 개선안은 `~/.claude`에서 **허용목록(deny-by-default) 방식으로 저작 파일만** 추적하는 것이다
> — `CLAUDE.md`·`rules/`·`commands/`·`hooks/`·`agents/`·`statusline.sh`·`settings.json`.
> **통째 추적은 기각**했다(DEC-014): `~/.claude`는 저작 파일이 약 64K인 반면 도구 생성물이
> 약 300M이고(`projects/` 대화 트랜스크립트 269M · `file-history/` 18M · `history.jsonl` 등),
> 통째로 추적하면 ⑴ 트랜스크립트에 섞인 비밀정보가 원격으로 유출될 수 있고 ⑵ 매 세션 트리가
> 더러워져 정작 룰 변경 diff가 묻힌다.
>
> 미러가 스캐폴드의 **기계적 파생물이 아니라는 점**이 이 백로그의 근거다 — 글로벌 파일에는
> "글로벌 기본값" 헤더, 스캐폴드 없는 프로젝트용 조건부 표현, 글로벌 전용 섹션이 섞여 있어
> 재생성이 불가능하다. 따라서 자체 이력이 필요하다. 진행 현황은
> `.claude/workspace/todo.md`의 BACKLOG-001 참조.

### 대안 2 — 운영 문서로 문서화 (METHODOLOGY.md)

방법론 전체를 사람이 따라가는 **단계별 게이트 체크리스트** 한 문서로 정리하는 방식.
게이트 내용은 위 [§작업 사이클 게이트](#작업-사이클-게이트-매-작업-동일)와 동일하다. 이 README의
해당 섹션 + `.claude/rules/`가 이미 대안 2의 역할을 겸하며, 별도 `METHODOLOGY.md`로 떼어내
단독 검토·공유용으로 쓸 수도 있다.

---

## Changelog

> 외부 공개용 요약. 내부 상세 이력은 `.claude/workspace/changelog.md`.
> 릴리즈는 `/release <major|minor|patch>` 로 끊습니다.

### v0.2.0 (2026-08-07)

파생 프로젝트 사용 피드백을 반영한 릴리즈. 대외 문서가 낡는 것을 기계로 잡고, 파생 프로젝트가
받아온 스캐폴드 버전을 알 수 있게 했습니다.

- **feat**: `.claude/SCAFFOLD-VERSION` — 파생 프로젝트가 받아온 스캐폴드 버전. 코드를 diff하지
  않고 업스트림과 숫자만 비교하면 됩니다. `/release`가 함께 갱신합니다.
- **feat**: `check-docs` **§8 README 버전 반영 검사** — 직전 릴리즈는 README에 있는데 현재
  버전이 없으면 경고합니다. 버전을 README에 적지 않는 프로젝트에서는 검사를 건너뜁니다.
- **feat**: `check-docs` **§9 필수 납품 문서 존재 검사** — `README.md`와 `CLAUDE.md`(루트
  또는 `.claude/`)가 아예 없는 상태를 잡습니다.
- **feat**: `check-docs` **§7 BACKLOG 상태 정합성 검사** — 릴리즈된 changelog나 완료
  체크박스가 언급한 BACKLOG인데 표가 미완료면 경고합니다.
- **docs**: 완료 시 자동 갱신 묶음이 8항목이 되었습니다(BACKLOG 표 갱신이 별도 항목으로 승격).

### v0.1.0 (2026-07-27)

첫 릴리즈. 방법론 룰 9종 + 얕은 harness 척추가 갖춰지고, 실제 브라운필드 적용 피드백을
반영한 시점.

- **feat**: 버전·changelog 정합성 harness — 버전 SoT 자동 감지(매니페스트 우선 → `VERSION`),
  changelog 스테일 검사, 버전 3자 일치 검사, `/release` 슬래시 커맨드.
- **feat**: 얕은 harness 척추 — `check-docs.sh` · Stop hook(비차단) · CI(strict 차단) ·
  슬래시 커맨드 3종(`/dec` · `/new-feature` · `/release`).
- **feat**: 방법론 룰 9종 + 요구사항 2분할(REQ/FR) + DEC 결정 로그 + 납품 문서 골격
  (사용자 가이드 · How It Works).
- **fix**: `/dec` 가 로그를 비운 상태(부트스트랩 직후)에서 항목을 앞 문단에 접합하던 버그.
- **fix**: 문서 정합성 검사가 한국어 열거형·규약 산문을 플레이스홀더로 오인하던 오탐.
- **docs**: brownfield 적용 절차를 코드/문서 2축 판별 + 경로 충돌 조정 0단계로 개정.

