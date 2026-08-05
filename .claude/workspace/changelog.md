# Changelog (내부 상세 이력)

> 작업하며 쌓는 **내부용 상세 기술 이력**. 외부 공개 요약은 `README.md`의 Changelog.
> 규칙: `.claude/rules/readme-sync.md`. 완료 후 여기에 먼저 기록하고, 의미 있는 항목만 README 반영.
> 릴리즈는 손으로 마감하지 말고 `/release` 를 쓴다(버전 SoT·이 파일·README를 동시에 갱신).
>
> ⚠️ **대상 프로젝트에 스캐폴드를 적용할 때**: 아래는 스캐폴드 레포 자신의 이력이므로
> 전부 비우고 대상 프로젝트 이력으로 새로 시작한다(→ README 적용 절차).

## [Unreleased]

### 2026-08-05
- **feat**: `check-docs` §7 BACKLOG 상태 정합성 검사 신설 — (A) changelog의 `feat`/`fix`
  항목이 언급한 BACKLOG인데 표가 미완료, (B) `- [x]` 완료 체크박스가 언급했는데 표가 미완료,
  (C) 표에 없는 BACKLOG 댕글링 참조. 표 행이 0개면 스킵. 파생 프로젝트에서 구현·릴리즈까지
  끝난 항목이 `진행중`으로 남아 있던 사고가 발단. 관련 DEC-015 / BACKLOG-003
- **fix**: §7-A를 릴리즈 구간 전체가 아니라 `feat`/`fix` 항목으로 한정. 구현 직후 이 레포
  자신의 v0.1.0 changelog(`- **docs**: … BACKLOG-001로 기록.`)에서 오탐이 재현됐고,
  changelog를 고쳐 경고를 숨기는 것은 이력 왜곡이라 검사 쪽을 좁혔다. 관련 DEC-016
- **docs**: `readme-sync` 갱신 묶음 7→8항목 — BACKLOG 행 갱신을 별도 줄로 승격(2번과 합치지
  않는 이유는 체크리스트가 줄 단위로 소비되기 때문). BACKLOG 표는 4열 유지 + `spec/plan`
  → `근거` 로 의미 확장(완료일은 상태 칸에 괄호로). 관련 DEC-015
- **test**: `test-check-docs.sh`에 §7 케이스 8건 추가 — 정탐 4건(A 릴리즈 구간·A 여러 줄
  feat 항목·B 자기모순·C 댕글링), 오탐 방지 4건(표 없으면 스킵·`[Unreleased]` 언급·docs 항목
  언급·백틱/펜스 제외).

### 2026-07-27
- **docs**: 스캐폴드 → 글로벌 룰 미러링 수행(`git-workflow`·`readme-sync`·`project-init`).
  통째 복사가 아니라 실질 변경분만 이식 — 글로벌 헤더·조건부 표현·글로벌 전용 섹션 보존,
  `/release`는 `scripts/new-release.sh`가 있는 프로젝트로 한정.
- **docs**: BACKLOG-001 문구를 "통째 추적" → "허용목록 방식 저작 파일만 추적"으로 수정.
  실측 근거(저작 64K vs 도구 생성물 300M)와 기각 사유는 DEC-014. 실행은 보류.

## v0.1.0 (2026-07-27)

첫 릴리즈. 방법론 룰 9종 + 얕은 harness 척추(스크립트·슬래시 커맨드·Stop hook·CI)가
갖춰지고, 실제 브라운필드 적용 피드백을 반영한 시점까지의 이력을 커밋에서 백필했다.

### 2026-07-27
- **feat**: 버전·changelog 정합성 harness — `lib-version.sh`(버전 SoT 자동 감지: 매니페스트
  우선 → `VERSION` 폴백), `check-docs` §5 changelog 스테일 검사(feat/fix 3건 유예,
  워킹트리에서 고치는 중이면 면제),
  §6 버전 3자 일치(SoT ↔ changelog ↔ tag), `/release`(파일 변경까지만, git 부작용 없음).
  관련 DEC-011 / BACKLOG-002
- **fix**: `new-dec.sh` append 전 말미 정규화 — 부트스트랩 지시대로 로그를 비우면 앵커가
  사라져 새 DEC가 앞 문단에 접합되던 버그(모든 신규 프로젝트의 첫 `/dec`에서 100% 재현).
  개행 없이 끝나는 파일도 함께 해소. 관련 DEC-012
- **fix**: `check-docs` 플레이스홀더 오탐 제거 — 코드펜스 전체 제외(한국어 열거형·스키마
  표기를 원본에서 그대로 옮길 수 있게), ID 리터럴에 한해 인라인 코드 제외(규약 산문).
  배포 `CLAUDE.md` 기준 14건 → 0건. 백틱 일괄 제외는 스켈레톤 Configuration 표의
  `VAR_NAME` 정탐을 잃어 채택하지 않음. 관련 DEC-012
- **feat**: `check-docs` §4 DEC 댕글링 참조 검사 신설(REQ/FR과 동일 방식). 룰 본문의 실제
  DEC 참조도 함께 제거해 복사 직후 상태를 깨끗하게. 관련 DEC-012
- **docs**: brownfield 적용 절차 개정 — 판별을 코드 축/문서 축 2축 매트릭스(4유형)로 교체,
  §B에 ⓪ 경로 충돌 조정 신설(복사 전 정본 판정), ③ 역설계를 코드 축 조건부로 명시.
  관련 DEC-013
- **test**: `test-new-dec.sh` 신규(8케이스) + CI 스텝 추가. `test-check-docs.sh`에 15케이스
  추가(펜스/백틱 제외·정탐 유지·DEC 댕글링·복사 직후 상태·changelog 스테일·버전 3자 일치).
- **chore**: CI `fetch-depth: 0` — 기본 shallow clone에서 §5가 무력화되는 것을 방지.
- **fix**: `check-docs` 플레이스홀더 검출 고도화 + 회귀 테스트(거짓 초록불 해소). 관련 DEC-010

### 2026-07-19
- **feat**: 얕은 harness 척추 도입 — Stop hook(비차단) · 슬래시 커맨드 2종(`/dec`·
  `/new-feature`) · CI(strict 차단). 로컬은 부드럽게, 병합 지점은 엄격하게.
  관련 DEC-006 / DEC-007
- **docs**: Git 워크플로 룰 추가 — 위험도 기반 브랜치 전략(방법론 룰 9번째). 관련 DEC-008
- **docs**: How It Works 문서(동작 원리·납품용) 추가 — 정적 구조(architecture)와 상보적인
  동적 흐름 문서. 관련 DEC-009
- **docs**: 글로벌 룰 버전 관리를 README 로드맵 + BACKLOG-001로 기록.

### 2026-07-18
- **feat**: 문서 정합성 검사 스크립트(`check-docs.sh`) · 팀 공유 `settings.json` 동봉.
  관련 DEC-004
- **docs**: 점검 결과 반영 — 참조-실체 일치 · 납품 관점 · 룰 중복 제거. 프로젝트 명령어
  파일을 `.claude/rules/commands.md`로 배치(DEC-003), 사용자 가이드를 `docs/user-guide.md`로
  이동(DEC-005), 글로벌 룰 충돌을 "병합 + 우선순위 선언"으로 해소(DEC-002).

### 2026-07-07
- **docs**: 레포명을 `claude-project-scaffold`로 변경, README를 코딩 에이전트 지향으로 재작성.
- **docs**: 전제 조건(Prerequisites) 섹션 추가 — superpowers(권장) · frontend-design(선택).
- **docs**: 요구사항 2분할 파일명을 의도가 드러나게 변경(`01-impl-*` / `01-user-*`).

### 2026-06-30
- **feat**: 프로젝트 방법론 스캐폴드 템플릿 초기 구성. 관련 DEC-001
- **docs**: README에 greenfield/brownfield 적용 가이드 분리 작성, 방법론 패키징 방식
  3종(스캐폴드 / 글로벌 룰 승격 / 운영 문서) 비교 부록 추가.
