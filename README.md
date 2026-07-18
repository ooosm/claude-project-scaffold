# claude-project-scaffold

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
| **얕은 harness(척추)** | 런타임에 실제로 실행·검사·차단하는 장치 | `scripts/check-docs.sh`, Stop hook, 슬래시 커맨드(`/dec`·`/new-feature`), CI | **강제** — 저비용·고신뢰 불변식만 기계로 못 박음 |

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

## greenfield / brownfield 판별

| 신호 | 판정 |
|------|------|
| 대상 디렉토리가 비어 있음 / 소스 파일 없음 / git 이력 없음 | **greenfield** |
| 기존 소스 코드 · `CLAUDE.md` · `README.md` · git 커밋 이력 중 하나라도 존재 | **brownfield** |

확신이 서지 않으면 사용자에게 확인한다. **오판 시 위험이 큰 쪽은 brownfield** — 기존 파일을
덮어쓸 수 있으므로, 애매하면 brownfield로 취급해 선별 병합한다.

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
| ⑦ | 버전 관리 + 외부 의존성 호환 버전 명시 | 호환 버전을 근거(DEC)와 함께 고정 | `.claude/rules/conventions.md`, 대상 README Dependencies |

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
│   ├── check-docs.sh               ← 문서 정합성 검사(플레이스홀더·REQ/FR 참조·DEC 번호)
│   ├── new-dec.sh                  ← DEC 번호 원자 할당 (/dec 가 호출)
│   └── new-feature.sh              ← spec/plan 골격 생성 (/new-feature 가 호출)
├── docs/
│   ├── user-guide.md               ← 사용자 가이드 골격(사람용 납품 문서 — 숨김 폴더 밖)
│   └── superpowers/
│       ├── specs/   _TEMPLATE-design.md   ← brainstorming 산출물 골격 (+ mockups/)
│       └── plans/   _TEMPLATE-plan.md     ← writing-plans 산출물 골격
└── .claude/
    ├── CLAUDE.md                   ← 200줄 이하 + @import (방법론 룰 9종 + commands)
    ├── settings.json               ← 팀 공유 설정 + Stop hook(비차단 check-docs)
    ├── commands/                   ← 슬래시 커맨드 /dec · /new-feature (harness 동사)
    ├── rules/                      ← 방법론 룰 9종 + commands.md(프로젝트 명령어)
    ├── decisions/                  ← 결정 로그 + ADR 템플릿 (append-only 누적)
    ├── docs/                       ← 요구사항(2종) + 아키텍처 (영구)
    └── workspace/                  ← 진행 현황판 + 내부 changelog (실시간 갱신)
```

### `.claude/` — 누적·영구 산출물

| 파일 | 에이전트 관점 역할 |
|------|--------------------|
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
| `workspace/todo.md` | ④ 실시간 현황판(🔄 진행/✅ 완료/⏳ 대기/🚧 블로커) + BACKLOG 표 |
| `workspace/changelog.md` | 내부 상세 기술 이력(외부 요약은 대상 README의 Changelog) |

### `docs/` — 사람용 납품 문서 + 작업 단위 산출물

| 파일 | 에이전트 관점 역할 |
|------|--------------------|
| `user-guide.md` | ⑥ 사용자 가이드 골격(사람용 납품 문서). 실제 구현 근거로 작성·갱신 |
| `superpowers/specs/_TEMPLATE-design.md` | brainstorming 설계 정본 골격. **복사**해서 `YYYY-MM-DD-*-design.md` 생성 |
| `superpowers/specs/mockups/` | ② UI 목업(.html) 저장 위치 |
| `superpowers/plans/_TEMPLATE-plan.md` | writing-plans 작업 분해 골격. **복사**해서 `YYYY-MM-DD-*.md` 생성 |

> `_TEMPLATE-*.md`는 **삭제하지 않는다** — 매 작업마다 복사 원본으로 재사용한다.

### `scripts/`·`.claude/commands/`·`.github/` — 얕은 harness 척추

| 파일 | 역할 | 성격 |
|------|------|------|
| `scripts/check-docs.sh` | 플레이스홀더 잔존·REQ/FR 댕글링 참조·DEC 번호 검사. 템플릿 자기감지(`_skeleton-README.md`)로 스캐폴드 자신은 플레이스홀더 검사 생략 | 강제(경고/strict) |
| `scripts/new-dec.sh` | 다음 DEC 번호 **원자 할당** + 골격 append (병렬 세션 충돌 예방) | 강제(결정론) |
| `scripts/new-feature.sh` | 오늘 날짜로 spec/plan 골격 생성 | 강제(결정론) |
| `.claude/commands/dec.md` | `/dec <제목>` — new-dec.sh 호출 후 결정 내용 작성 안내 | harness 동사 |
| `.claude/commands/new-feature.md` | `/new-feature <slug>` — new-feature.sh 호출 후 brainstorming 게이트 안내 | harness 동사 |
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

> ⚠️ **핵심 함정**: `cp -r`로 통째 덮어쓰면 기존 `CLAUDE.md`·`README.md`가 사라진다.
> 아래 3분류를 반드시 지킨다.

**① 그대로 복사해도 안전** (순수 방법론, 기존 코드 무영향)

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
| `README.md` | 기존 README 유지. 스캐폴드 소개용 README는 brownfield엔 불필요 |
| `.gitignore` | 누락된 줄(`settings.local.json` 등)만 append |
| `.claude/settings.json` | 이미 있으면 병합 |
| `_skeleton-README.md` | 이미 README가 있으니 **삭제** |

**③ brownfield 고유 작업 = 역설계(retroactive), 점진적으로**

greenfield는 "앞으로 만들 것"을 적지만 brownfield는 **이미 만든 것을 거꾸로 문서화**한다.
유일한 큰 비용이지만 한 번에 다 할 필요는 없다.

- **requirements(REQ/FR)**: 돌고 있는 앱·엔드포인트에서 추출. 처음엔 골격 + 핵심 기능 몇 개만, 이후 작업하며 증분 등록(100% 선행 금지).
- **architecture**: 현재 코드 구조를 한 번 훑어 `.claude/docs/02-architecture.md` 골격을 채운다.
- **decision-log**: 과거 결정은 복구 불가 → **지금부터** 로깅 시작. 아직 살아있는 **큰** 과거 결정(스택 선택·핵심 의존성 버전 고정 등) 3~5개만 ADR로 선택 백필하면 추적성이 크게 향상.

**권장 도입 순서**

```
1. rules/decisions/workspace/scripts/superpowers 복사  (안전, 코드 무영향)
2. CLAUDE.md 병합 (기존 보존 + @import·핵심원칙 추가)
3. 현재 진행 상황을 workspace/todo.md에 스냅샷
4. 코드 훑어 02-architecture.md 작성 (현재 상태)
5. requirements 골격 생성 → 핵심 기능부터 점진 채움
6. 살아있는 과거 큰 결정만 ADR 백필, 이후 DEC 즉시 로깅 시작
7. _skeleton-README.md 삭제, 기존 README는 유지 (이후 readme-sync 규칙으로 동기화)
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

greenfield 추가
- [ ] _skeleton-README.md 를 README.md 로 교체하고 스캐폴드 소개 README를 정리했는가
- [ ] _TEMPLATE-*.md(spec/plan)는 남겨 두었는가

brownfield 추가
- [ ] 기존 CLAUDE.md·README.md·.gitignore 를 덮어쓰지 않고 "병합"했는가
- [ ] _skeleton-README.md 를 삭제했는가
- [ ] requirements/architecture 골격을 만들고 핵심부터 점진 채우기를 시작했는가
```

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

### 대안 2 — 운영 문서로 문서화 (METHODOLOGY.md)

방법론 전체를 사람이 따라가는 **단계별 게이트 체크리스트** 한 문서로 정리하는 방식.
게이트 내용은 위 [§작업 사이클 게이트](#작업-사이클-게이트-매-작업-동일)와 동일하다. 이 README의
해당 섹션 + `.claude/rules/`가 이미 대안 2의 역할을 겸하며, 별도 `METHODOLOGY.md`로 떼어내
단독 검토·공유용으로 쓸 수도 있다.
