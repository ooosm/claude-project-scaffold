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

## 새 프로젝트 부트스트랩

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
