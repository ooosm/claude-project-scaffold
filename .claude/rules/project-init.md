# 프로젝트 초기화 규칙

> 방법론 구성요소 ① superpowers 산출물 ↔ `.claude/` 통합 관리

## 전체 디렉토리 구조

```
프로젝트 루트/
├── CLAUDE.md                        ← 핵심 요약 + @import만 (200줄 이하)
├── README.md                        ← 자동 업데이트 대상(기능 변경 시 반영)
├── .gitignore
├── .github/workflows/
│   └── check-docs.yml               ← CI: push/PR에서 check-docs --strict (차단)
├── VERSION                          ← 버전 SoT(언어 매니페스트가 없을 때만 — 있으면 그쪽이 정본)
├── scripts/
│   ├── check-docs.sh                ← 문서 정합성 검사(플레이스홀더·참조·DEC·changelog·버전·BACKLOG)
│   ├── lib-version.sh               ← 버전·changelog 조회 함수(check-docs·new-release 공유)
│   ├── new-release.sh               ← 릴리즈 끊기 (/release)
│   ├── test-check-docs.sh           ← check-docs 검출 로직 회귀 테스트 (CI)
│   ├── test-new-dec.sh              ← new-dec 번호 할당·말미 정규화 회귀 테스트 (CI)
│   ├── new-dec.sh                   ← DEC 번호 원자 할당 (/dec)
│   └── new-feature.sh               ← spec/plan 골격 생성 (/new-feature)
├── docs/
│   ├── user-guide.md                ← 사용자 가이드(사람용 납품 문서 — 숨김 폴더 밖)
│   ├── how-it-works.md              ← 동작 원리(트리거별 흐름, Mermaid — 사람용 납품 문서)
│   └── superpowers/
│       ├── specs/                   ← brainstorming 산출물(설계 정본) + mockups/
│       └── plans/                   ← writing-plans 산출물(작업 분해)
└── .claude/
    ├── CLAUDE.md                    ← (선택) 루트 CLAUDE.md와 통합 가능
    ├── settings.json                ← 팀 공유 설정 + Stop hook(비차단 check-docs)
    ├── settings.local.json          ← 개인 로컬 설정 (.gitignore)
    ├── commands/                    ← 슬래시 커맨드(/dec, /new-feature, /release) — harness 동사
    ├── rules/                       ← 방법론 룰 9종 + commands.md(프로젝트 명령어)
    ├── decisions/                   ← DEC 로그 + ADR (git 포함, 영구)
    ├── docs/                        ← 요구사항(01)·아키텍처(02) (영구)
    └── workspace/                   ← Claude가 관리하는 작업 파일 (git 포함)
        ├── todo.md                  ← 실시간 단일 현황판
        └── changelog.md             ← 내부 상세 이력
```

## 문서 번호 규약 (`.claude/docs/`)

- `01-*` 요구사항(impl/user 2분할) / `02-*` 아키텍처 / `03~09` 예약(운영·보안 등 필요 시).
- **사람에게 전달되는 납품 문서**(사용자 가이드·동작 원리 등)는 `.claude/` 가 아닌 `docs/` 에 둔다.
- **정적 구조 vs 동적 흐름**: `.claude/docs/02-architecture.md`(무엇이 있나)와
  `docs/how-it-works.md`(트리거별로 어떻게 동작하나)는 상보적이며 서로 링크한다.

## 역할 구분

- `.claude/` → **누적·영구**: 결정(decisions), 요구사항·아키텍처(docs), 진행현황(workspace).
- `docs/superpowers/` → **작업 단위 산출물**: spec(설계), plan(구현 계획).
- 둘은 ID(BACKLOG/DEC/REQ/FR)로 상호 참조하여 **단일 흐름**으로 연결.

## CLAUDE.md 작성 원칙

- **200줄 이하** 유지. 상세는 `.claude/rules/` 로 분리하고 `@import` 참조.
- 핵심 원칙(Source of Truth, 스택·호환버전, 표준)을 최상단에 요약.

## .gitignore 필수 항목

```
.claude/settings.local.json
node_modules/
dist/
```

> `workspace/`는 git에 **포함**한다 — 사용자가 직접 열어 진행 현황을 확인하기 위함.

## Brownfield 주의사항

- **문서 규약이 이미 있으면 복사 전에 정본 경로를 정한다.** 결정 로그·요구사항·아키텍처·진행
  현황 4종은 harness(`new-dec.sh`·`check-docs.sh`)가 경로를 하드코딩하므로, 기존 체계와
  경쟁하는 두 번째 정본이 조용히 생긴다. 판정과 근거는 DEC로 남긴다(→ 스캐폴드 README §B ⓪).
- **코드가 0줄이면 역설계를 건너뛴다.** 요구사항·아키텍처는 기획 문서에서 도출한다.
- 기존 코드베이스를 먼저 파악하고 `.claude/docs/`에 아키텍처를 기록한다.
- 팀이 이미 쓰는 컨벤션을 `conventions.md`에 반영하고, 임의로 패턴을 바꾸지 않는다.
- 기존 `README.md`가 있으면 내용을 **보존**하며 변경분만 반영한다.

## 이 템플릿으로 시작할 때

1. 이 구조를 새 프로젝트 루트에 복사한다.
2. 루트 `README.md`의 "새 프로젝트 부트스트랩" 체크리스트를 따른다.
3. `[프로젝트명]`·`[개요]` 등 플레이스홀더를 실제 값으로 치환한다.
4. 첫 작업은 **brainstorming → spec** 으로 시작한다(코딩 먼저 금지).
