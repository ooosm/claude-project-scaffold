# claude_template

> Claude Code로 작업하는 신규 프로젝트를 **일관된 개발 방법론**으로 시작하기 위한 재사용 스캐폴드(방법 B: 스캐폴드 레포).
> 결정 추적 · 요구사항 관리 · 문서 동기화 · UI 목업 게이트가 처음부터 폴더 구조로 들어가 있습니다.

신규 프로젝트에서 이 레포를 복사하면, brainstorming → spec → plan → 구현 → 문서 동기화로
이어지는 워크플로와 그 산출물이 놓일 자리가 이미 준비되어 있습니다. 자체 완결형이라
글로벌 룰(`~/.claude`) 없이 복사만으로 동작합니다.

---

## 방법론 7대 구성요소

| # | 구성요소 | 핵심 | 관련 문서 |
|---|----------|------|-----------|
| ① | superpowers 산출물 ↔ `.claude/` 통합 흐름 | spec/plan ↔ 결정·요구사항·현황을 단일 흐름으로 연결 | `rules/project-init.md`, `docs/superpowers/` |
| ② | HTML 목업 우선(UI 설계 게이트) | 목업 검토 없이 UI 코드 작성 금지 | `rules/ui-mockups.md` |
| ③ | 의사결정 자동 로깅 | 선택+기각 대안 보존, append-only | `rules/decisions.md`, `decisions/` |
| ④ | 구현 현황 트래킹 + 자동 갱신 | 단계 완료 시 현황표·todo 자동 갱신 | `rules/requirements.md`, `docs/01-requirements.md`, `workspace/todo.md` |
| ⑤ | 요구사항 2분할 | 구현 관점(REQ) / 사용자 관점(FR) | `docs/01-requirements.md`, `docs/01-a-func_requirements.md` |
| ⑥ | 사용자 가이드 — 실제 구현 근거 작성 | 추측 금지, 코드 확인 후 갱신 | `rules/readme-sync.md`, `docs/10-user-guide.md` |
| ⑦ | 버전 관리 + 외부 의존성 호환 버전 명시 | 호환 버전을 근거(DEC)와 함께 고정 | `rules/conventions.md`, 프로젝트 README Dependencies |

---

## 디렉토리 구조

```
claude_template/
├── README.md                       ← (이 파일) 템플릿 레포 소개 + 문서 개요
├── _skeleton-README.md             ← 새 프로젝트가 README.md로 복사해 쓰는 스켈레톤
├── .gitignore
├── docs/superpowers/
│   ├── specs/   _TEMPLATE-design.md   ← brainstorming 산출물 골격
│   └── plans/   _TEMPLATE-plan.md     ← writing-plans 산출물 골격
└── .claude/
    ├── CLAUDE.md                   ← 200줄 이하 + @import (룰 8종 + 산출물 흐름도)
    ├── rules/                      ← 방법론 룰 8종
    ├── decisions/                  ← 결정 로그 + ADR 템플릿
    ├── docs/                       ← 요구사항(2종) + 사용자 가이드
    └── workspace/                  ← 진행 현황판 + 내부 changelog
```

---

## 템플릿 문서 개요

각 파일이 무엇을 담는지에 대한 개요입니다. 골격(플레이스홀더 포함)으로 제공되며,
새 프로젝트에서 실제 내용으로 채웁니다.

### 루트

| 파일 | 개요 |
|------|------|
| `README.md` | 이 파일. 템플릿 레포 소개와 전체 문서 개요. 새 프로젝트에선 `_skeleton-README.md`로 교체. |
| `_skeleton-README.md` | 새 프로젝트의 README 스켈레톤(Features/Prerequisites/Configuration/Dependencies/Changelog). |
| `.gitignore` | `settings.local.json`·`node_modules`·`dist` 등 무시. `workspace/`는 git 포함. |

### `.claude/` — 누적·영구 산출물

| 파일 | 개요 |
|------|------|
| `CLAUDE.md` | 프로젝트 핵심 요약 + 룰 `@import` 목록 + 산출물 흐름도. **200줄 이하** 유지. |
| `rules/project-init.md` | ① 디렉토리 구조·역할 구분(누적 vs 작업단위)·brownfield 주의·부트스트랩. |
| `rules/planning.md` | 워크플로 게이트(brainstorming→plan→구현→갱신), spec/plan 머리말 규칙. |
| `rules/requirements.md` | ④⑤ 요구사항 2분할(REQ/FR)·구현 현황 요약 표·자동 갱신 규칙. |
| `rules/decisions.md` | ③ DEC 자동 로깅 형식·append-only·ADR 관계·의존성 버전 근거. |
| `rules/ui-mockups.md` | ② HTML 목업 우선 게이트(목업 없이 UI 코드 금지) 절차. |
| `rules/validation.md` | 빌드→단위→통합→타입/린트→수동 검증 순서, "테스트 없으면 미완료". |
| `rules/conventions.md` | 네이밍·커밋·주석 규칙 + ⑦ 버전 메타데이터·의존성 고정. |
| `rules/readme-sync.md` | ⑥ README/사용자 가이드 자동 동기화, 완료 시 갱신 묶음. |
| `decisions/decision-log.md` | 모든 결정 누적 로그(DEC-NNN). 채택 예시 1건 포함. **append-only**. |
| `decisions/ADR-000-template.md` | 큰 아키텍처 결정용 ADR 템플릿(맥락/결정/대안/결과). |
| `docs/01-requirements.md` | ⑤ 구현 관점 요구사항(REQ-N-M) + 구현 현황 요약 표(SoT). |
| `docs/01-a-func_requirements.md` | ⑤ 사용자 관점 기능 요구사항(FR-NN, 체크박스). |
| `docs/10-user-guide.md` | ⑥ 사용자 가이드 골격(실제 구현 근거로 작성·갱신). |
| `workspace/todo.md` | ④ 실시간 현황판(🔄 진행/✅ 완료/⏳ 대기/🚧 블로커) + BACKLOG 표. |
| `workspace/changelog.md` | 내부 상세 기술 이력(외부 요약은 프로젝트 README의 Changelog). |

### `docs/superpowers/` — 작업 단위 산출물

| 파일 | 개요 |
|------|------|
| `specs/_TEMPLATE-design.md` | brainstorming 설계 정본 골격(머리말에 BACKLOG/REQ/FR/DEC 상호참조). |
| `plans/_TEMPLATE-plan.md` | writing-plans 작업 분해 골격(태스크·검증 계획·완료 갱신 묶음). |

---

## 산출물 흐름 (단일 흐름)

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

## 적용 방법

이 템플릿은 **신규(greenfield)** 프로젝트를 1차 타겟으로 하지만, **기존(brownfield)**
프로젝트에도 적용할 수 있습니다. 둘은 룰이 같고 **도입 절차만 다릅니다** — greenfield는
"폴더 통째 복사", brownfield는 "선별 병합(merge)"입니다.

> ⚠️ **공통 함정**: brownfield에서 `cp -r`로 통째 덮어쓰면 기존 `CLAUDE.md`·`README.md`가
> 사라집니다. 기존 프로젝트에는 반드시 아래 **선별 병합** 절차를 따르세요.

### 신규 프로젝트(greenfield)에 적용 — 폴더 통째 복사

빈 프로젝트라 충돌이 없으므로 전체 구조를 그대로 가져옵니다.

```
1. 이 폴더 전체를 새 프로젝트 위치로 복사한다.
   - git 새로 시작: rm -rf .git && git init
2. 플레이스홀더([프로젝트명]·[개요]·[스택/호환버전]·YYYY-MM-DD)를 실제 값으로 치환한다.
   - 대상: .claude/CLAUDE.md, .claude/docs/*, .claude/workspace/*, _skeleton-README.md
3. _skeleton-README.md 를 README.md 로 복사해 채운다(이 템플릿 소개 README는 덮어쓴다).
4. .claude/CLAUDE.md 를 루트로 쓸지 결정한다(루트 CLAUDE.md가 있으면 Claude가 자동 로드).
5. _TEMPLATE-*.md(spec/plan 템플릿)는 남겨 두고, 실제 작업은 복사해서 만든다.
6. 첫 작업은 brainstorming → spec 으로 시작한다(코딩 먼저 금지).
7. 불필요한 템플릿 안내 파일(_skeleton-README.md 등)을 삭제한다.
```

### 기존 프로젝트(brownfield)에 적용 — 선별 병합

이미 코드·`CLAUDE.md`·`README`·git 히스토리가 있으므로 **통째 복사 금지**.
바뀌는 건 룰이 아니라 도입 절차뿐입니다(룰 자체는 이미 brownfield 우선 원칙을 따름 —
`rules/project-init.md`의 Brownfield 주의사항, `rules/conventions.md` 참조).

**① 그대로 복사해도 안전한 것** (순수 방법론, 기존 코드 무영향)

| 대상 | 이유 |
|------|------|
| `.claude/rules/` 8종 | 프로젝트 무관한 작업 방식. 코드를 건드리지 않음 |
| `.claude/decisions/` | 빈 로그를 **지금부터** 누적 시작 |
| `.claude/workspace/` | 현재 진행 현황을 스냅샷으로 채움 |
| `docs/superpowers/specs|plans/` 템플릿 | 다음 작업부터 사용 |

**② 덮어쓰지 말고 "병합"할 것** ⚠️

| 대상 | 처리 |
|------|------|
| `CLAUDE.md` | 기존 내용 보존 + 템플릿의 `@import`·산출물 흐름만 **추가 병합** (overwrite 금지) |
| `README.md` | 기존 README 유지. 템플릿 소개용 README는 brownfield엔 불필요 |
| `.gitignore` | 누락된 줄(`settings.local.json` 등)만 append |
| `.claude/settings.json` | 이미 있으면 병합 |
| `_skeleton-README.md` | 이미 README가 있으니 **삭제** |

**③ Brownfield 고유 작업 = 역설계(retroactive), 점진적으로**

greenfield는 "앞으로 만들 것"을 적지만 brownfield는 **이미 만든 것을 거꾸로 문서화**합니다.
유일한 큰 비용이지만 한 번에 다 할 필요는 없습니다.

- **requirements(REQ/FR)**: 돌고 있는 앱·엔드포인트에서 추출. 처음엔 골격 + 핵심 기능 몇 개만, 이후 작업하며 증분 등록(100% 선행 금지).
- **architecture**: 현재 코드 구조를 한 번 훑어 `.claude/docs/02-architecture.md`로 스냅샷.
- **decision-log**: 과거 결정은 복구 불가 → **지금부터** 로깅 시작. 단, 아직 살아있는 **큰** 과거 결정(스택 선택·핵심 의존성 버전 고정 등) 3~5개만 ADR로 선택 백필하면 추적성이 크게 향상.

**④ 권장 도입 순서**

```
1. rules/decisions/workspace/superpowers 복사  (안전, 코드 무영향)
2. CLAUDE.md 병합 (기존 보존 + @import·핵심원칙 추가)
3. 현재 진행 상황을 workspace/todo.md에 스냅샷
4. 코드 훑어 02-architecture.md 작성 (현재 상태)
5. requirements 골격 생성 → 핵심 기능부터 점진 채움
6. 살아있는 과거 큰 결정만 ADR 백필, 이후 DEC 즉시 로깅 시작
7. _skeleton-README.md 삭제, 기존 README는 유지 (이후 readme-sync 규칙으로 동기화)
8. 첫 작업부터 brainstorming → spec 게이트 적용
```

---

## 운영 흐름 (매 작업 동일 게이트)

1. brainstorming → `docs/superpowers/specs/YYYY-MM-DD-*-design.md` (UI면 **목업 게이트**)
2. writing-plans → `docs/superpowers/plans/YYYY-MM-DD-*.md`, `todo.md`에 태스크 등록
3. 결정 발생 시 **즉시 DEC 로깅**(`.claude/decisions/decision-log.md`)
4. 구현 → 태스크별 리뷰 → 최종 리뷰
5. 완료 시 **자동 갱신 묶음**: 구현현황표 + todo + changelog + README + 사용자 가이드
6. 의존성 변경 시 **호환 버전 + 근거**를 DEC와 Prerequisites에 기록

---

## 방법 A·C와의 관계

- **방법 A(글로벌 룰)**: `~/.claude/rules/`에 같은 룰을 두면 모든 프로젝트에 자동 상속.
  이 템플릿은 자체 완결형이라 글로벌 룰 없이도 동작한다(병행 가능).
- **방법 C(METHODOLOGY.md)**: 이 README + `.claude/rules/`가 운영 규칙 문서 역할을 겸한다.
