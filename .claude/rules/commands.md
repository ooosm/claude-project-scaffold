# 프로젝트 명령어 (Commands)

> **프로젝트 고유 정보** 파일이다(방법론 룰 9종과 달리 프로젝트마다 내용이 다름).
> 부트스트랩 시 실제 명령어로 채운다. `validation.md`의 각 검증 단계가 이 파일을 참조한다.

## 개발 명령어

| 용도 | 명령어 | 비고 |
|------|--------|------|
| 빌드 | `[예: npm run build]` | 검증 1단계 |
| 단위 테스트 | `[예: npm run test:unit]` | 검증 2단계 |
| 통합 테스트 | `[예: npm run test:integration]` | 검증 3단계 |
| 타입 검사 | `[예: npm run type-check]` | 검증 4단계 |
| 린트 | `[예: npm run lint]` | 검증 4단계 |
| 로컬 실행 | `[예: npm run dev]` | 수동 검증용 |

## harness 동사 (슬래시 커맨드 · 스크립트)

이 레포는 얕은 harness다 — 반복·정합성 작업은 손이 아니라 아래 동사로 처리한다.

| 커맨드 | 스크립트 | 하는 일 |
|--------|----------|---------|
| `/dec <제목>` | `scripts/new-dec.sh` | 다음 DEC 번호 **원자 할당** + 골격 append (병렬 세션 충돌 예방) |
| `/new-feature <slug>` | `scripts/new-feature.sh` | 오늘 날짜로 spec/plan 골격 생성 → brainstorming 게이트 진입 |
| `/release <bump>` | `scripts/new-release.sh` | 버전 SoT bump(쓰기 후 재검증) + changelog 마감 + README 골격 삽입. **git 부작용 없음**(커밋·태그는 사람이) |

```bash
bash scripts/check-docs.sh          # 플레이스홀더·필수문서·REQ/FR·DEC·changelog 스테일·버전 3자 일치·BACKLOG 상태·README 버전 반영·스캐폴드 스탬프 (경고만, exit 0)
bash scripts/check-docs.sh --strict # 경고를 실패(exit 1)로 — CI/커밋 전 검사용
bash scripts/test-check-docs.sh     # check-docs 검출 로직 회귀 테스트 (CI에서 실행)
bash scripts/test-new-dec.sh        # new-dec 번호 할당·말미 정규화 회귀 테스트 (CI에서 실행)
bash scripts/new-dec.sh "제목"      # DEC 번호 원자 할당 (보통 /dec 로 호출)
bash scripts/new-feature.sh slug    # spec/plan 골격 생성 (보통 /new-feature 로 호출)
bash scripts/new-release.sh minor   # 릴리즈 끊기 (보통 /release 로 호출)
```

## 버전 정책

버전 SoT는 **자동 감지**된다 — `package.json` → `pyproject.toml` → `Cargo.toml` → 루트
`VERSION` 순으로 찾고, 하나도 없으면 버전 검사를 건너뛴다. 매니페스트가 있으면 그것이 이미
정본이므로 별도 버전 파일을 만들지 않는다(이중 관리는 드리프트를 부른다).

자동 감지를 **override 할 때만** 아래를 선언한다. 선언이 없으면 `semver` 로 동작한다.

```
version-policy: semver
```

| 값 | 동작 |
|----|------|
| `semver` (기본) | `X.Y.Z` 형식 검사 + `/release major\|minor\|patch` 자동 bump |
| `calver` | 형식 검사 없음. `/release` 에 **명시 버전**을 준다(예: `2026.07.1`) |
| `none` | 버전 검사(§6) OFF. 매니페스트에 version이 형식상 박혀 있으나 실제로는 릴리즈를 끊지 않는 private 내부 서비스용 |

## 강제 배선 (이미 켜져 있음)

- **로컬 Stop hook**: `.claude/settings.json`이 세션 종료 시 `check-docs.sh`를 **비차단**으로
  실행한다(경고만, 세션을 막지 않음). 스크립트가 없으면 무해하게 통과한다.
- **CI**: `.github/workflows/check-docs.yml`가 push/PR에서 `check-docs.sh --strict`로 **차단**한다.
- 설계 근거: 로컬은 부드럽게, 병합 지점은 엄격하게 — 작업 중에는 경고로 흐름을 끊지 않고,
  되돌리기 비싼 병합 지점에서만 차단한다.

> 각 단계/태스크 완료 시(자동 갱신 묶음 직후) `check-docs.sh` 실행을 권장한다.
