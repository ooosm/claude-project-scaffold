# 프로젝트 초기화 규칙

> 방법론 구성요소 ① superpowers 산출물 ↔ `.claude/` 통합 관리

## 전체 디렉토리 구조

```
프로젝트 루트/
├── CLAUDE.md                        ← 핵심 요약 + @import만 (200줄 이하)
├── README.md                        ← 자동 업데이트 대상(기능 변경 시 반영)
├── .gitignore
├── scripts/
│   └── check-docs.sh                ← 문서 정합성 검사(플레이스홀더·참조·DEC 번호)
├── docs/
│   ├── user-guide.md                ← 사용자 가이드(사람용 납품 문서 — 숨김 폴더 밖)
│   └── superpowers/
│       ├── specs/                   ← brainstorming 산출물(설계 정본) + mockups/
│       └── plans/                   ← writing-plans 산출물(작업 분해)
└── .claude/
    ├── CLAUDE.md                    ← (선택) 루트 CLAUDE.md와 통합 가능
    ├── settings.json                ← 팀 공유 설정 (git 포함)
    ├── settings.local.json          ← 개인 로컬 설정 (.gitignore)
    ├── rules/                       ← 방법론 룰 8종 + commands.md(프로젝트 명령어)
    ├── decisions/                   ← DEC 로그 + ADR (git 포함, 영구)
    ├── docs/                        ← 요구사항(01)·아키텍처(02) (영구)
    └── workspace/                   ← Claude가 관리하는 작업 파일 (git 포함)
        ├── todo.md                  ← 실시간 단일 현황판
        └── changelog.md             ← 내부 상세 이력
```

## 문서 번호 규약 (`.claude/docs/`)

- `01-*` 요구사항(impl/user 2분할) / `02-*` 아키텍처 / `03~09` 예약(운영·보안 등 필요 시).
- **사람에게 전달되는 납품 문서**(사용자 가이드 등)는 `.claude/` 가 아닌 `docs/` 에 둔다.

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

- 기존 코드베이스를 먼저 파악하고 `.claude/docs/`에 아키텍처를 기록한다.
- 팀이 이미 쓰는 컨벤션을 `conventions.md`에 반영하고, 임의로 패턴을 바꾸지 않는다.
- 기존 `README.md`가 있으면 내용을 **보존**하며 변경분만 반영한다.

## 이 템플릿으로 시작할 때

1. 이 구조를 새 프로젝트 루트에 복사한다.
2. 루트 `README.md`의 "새 프로젝트 부트스트랩" 체크리스트를 따른다.
3. `[프로젝트명]`·`[개요]` 등 플레이스홀더를 실제 값으로 치환한다.
4. 첫 작업은 **brainstorming → spec** 으로 시작한다(코딩 먼저 금지).
