#!/usr/bin/env bash
# check-docs.sh 회귀 테스트 — 플레이스홀더 검출의 정탐/오탐/Mermaid 제외를 검증한다.
# 임시 "대상 프로젝트"(_skeleton-README.md 없음 → 플레이스홀더 검사 활성)를 만들어
# check-docs.sh를 실제로 돌리고 출력/종료코드를 단언한다. CI에서 실행된다.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
FAIL=0
pass() { printf '  ✓ %s\n' "$1"; }
fail() { FAIL=1; printf '  ✗ %s\n' "$1"; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts" "$T/.claude/docs" "$T/.claude/decisions" "$T/docs"
cp "$HERE/check-docs.sh" "$T/scripts/check-docs.sh"

# 더티 문서: 플레이스홀더 잔존 + Mermaid 노드 라벨(비-ASCII 대괄호, 오탐 유발 후보)
cat > "$T/docs/how-it-works.md" <<'EOF'
# How It Works — [프로젝트명]
```mermaid
flowchart LR
    A[집계 엔진] --> B[(원천 데이터)]
    A --> C[스케줄러]
```
설명은 실제 동작 기준으로 작성한다.
설치 전 `VAR_NAME` 환경변수를 확인한다.
EOF

# 클린 문서: 정상 표기만(체크박스·한글 링크·[Unreleased]·코드 인덱싱) → 오탐 0이어야
cat > "$T/docs/user-guide.md" <<'EOF'
# 사용자 가이드 — 마이프로젝트
- [x] 로그인 완료
- [ ] 로그아웃 예정
자세한 내용은 [공식 문서](https://example.com)를 참고하세요.
## [Unreleased]
예시 코드: config[key] 와 items[idx] 를 쓴다.
EOF

# 구조 검사(REQ/FR·DEC)를 조용히 통과시키기 위한 최소 픽스처
printf '%s\n' '### REQ-1-1: 로그인' > "$T/.claude/docs/01-impl-requirements.md"
printf '%s\n' '- **FR-01**: 로그인한다' > "$T/.claude/docs/01-user-requirements.md"
printf '%s\n' '## DEC-001: 초기 결정 (2026-01-01)' > "$T/.claude/decisions/decision-log.md"

OUT="$(cd "$T" && bash scripts/check-docs.sh 2>&1)"

echo "$OUT" | grep -q 'how-it-works.md' && pass "더티 문서의 플레이스홀더를 검출" || fail "더티 문서를 놓침"
echo "$OUT" | grep -q '집계 엔진\|스케줄러\|원천 데이터' && fail "Mermaid 노드 라벨을 오탐" || pass "Mermaid 노드 라벨 제외"
echo "$OUT" | grep -q 'VAR_NAME' && pass "VAR_NAME 검출" || fail "VAR_NAME 놓침"
echo "$OUT" | grep -q 'user-guide.md' && fail "클린 문서 오탐([x]/[ ]/링크/[Unreleased]/config[key])" || pass "클린 문서 오탐 없음"

# --strict 는 경고가 있으면 exit 1
(cd "$T" && bash scripts/check-docs.sh --strict >/dev/null 2>&1)
[ "$?" -eq 1 ] && pass "--strict 는 경고 시 exit 1" || fail "--strict 종료코드가 1이 아님"

# 클린 전용(더티 제거) → exit 0 이어야
rm -f "$T/docs/how-it-works.md"
(cd "$T" && bash scripts/check-docs.sh --strict >/dev/null 2>&1)
[ "$?" -eq 0 ] && pass "클린 문서만 남으면 --strict 통과" || fail "클린 문서인데 --strict 실패"

# ── 최소 대상 프로젝트 픽스처 헬퍼 ────────────────────────────────────────
# _skeleton-README.md 없음 → 플레이스홀더 검사 활성. 구조 검사는 조용히 통과하는 최소 구성.
new_project() {
  d="$1"
  mkdir -p "$d/scripts" "$d/.claude/docs" "$d/.claude/decisions" "$d/.claude/rules" "$d/docs"
  mkdir -p "$d/.claude/workspace"
  cp "$HERE/check-docs.sh" "$d/scripts/check-docs.sh"
  cp "$HERE/lib-version.sh" "$d/scripts/lib-version.sh"
  printf '%s\n' '### REQ-1-1: 로그인' > "$d/.claude/docs/01-impl-requirements.md"
  printf '%s\n' '- **FR-01**: 로그인한다' > "$d/.claude/docs/01-user-requirements.md"
  printf '%s\n' '## DEC-001: 초기 결정 (2026-01-01)' > "$d/.claude/decisions/decision-log.md"
}

# ── 코드펜스 제외 (일반 펜스도 mermaid와 동일하게) ────────────────────────
# 한국어 기술 문서에서 대괄호는 열거형의 관용 표기다. 원본 기획서의 스키마·열거형을
# 그대로 옮길 수 있어야 한다.
P="$T/fence"; new_project "$P"
cat > "$P/docs/user-guide.md" <<'EOF'
# 사용자 가이드 — 마이프로젝트
```
Application(신청) : id, campaignId, 상태[신청|선정|탈락|방문완료|노쇼]
```
```text
설정 파일 경로는 YYYY-MM-DD 형식의 디렉토리에 둔다.
```
본문은 정상 표기만 사용한다.
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'user-guide.md' \
  && fail "일반 코드펜스 안 열거형·날짜를 오탐" || pass "일반 코드펜스 제외(열거형·날짜 표기)"

# ── 백틱 인라인 코드 안 ID 리터럴 제외 + bare 는 계속 검출 ────────────────
# 규약을 설명할 때는 관례적으로 `DEC-NNN`처럼 백틱을 쓴다. 반면 치환 대상 플레이스홀더는
# 맨몸으로 남는다. 이 구분으로 오탐만 걷어내고 정탐은 유지한다.
P="$T/backtick"; new_project "$P"
cat > "$P/docs/user-guide.md" <<'EOF'
# 사용자 가이드 — 마이프로젝트
- spec 머리말에 `BACKLOG-NNN`·`DEC-NNN`·`REQ-N-M`·`FR-NN`을 상호 참조로 명시한다.
- 결정은 `decision-log.md`에 `## DEC-NNN` 으로 추가한다.
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'user-guide.md' \
  && fail "백틱 안 ID 리터럴을 오탐(규약 설명 산문)" || pass "백틱 안 ID 리터럴 제외"

P="$T/bareid"; new_project "$P"
printf '%s\n' '# 사용자 가이드 — 마이프로젝트' '- **관련**: FR-01, DEC-NNN' > "$P/docs/user-guide.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'user-guide.md' \
  && pass "백틱 없는 ID 플레이스홀더는 계속 검출(정탐 유지)" || fail "bare ID 플레이스홀더를 놓침"

# ── DEC 댕글링 참조 검사 ──────────────────────────────────────────────────
# 부트스트랩이 로그를 비우라고 지시하므로, 룰·문서 본문이 참조하는 DEC 번호가 존재하지
# 않는 결정이 되는 일이 생긴다. REQ/FR과 동일한 방식으로 잡는다.
P="$T/decdangling"; new_project "$P"
printf '%s\n' '# 명령어' '- 설계 근거: 로컬은 부드럽게(DEC-006).' > "$P/.claude/rules/commands.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'DEC-006' && pass "댕글링 DEC 참조 검출" || fail "댕글링 DEC 참조를 놓침"

# 형식 예시(코드펜스 안)와 백틱 표기는 참조가 아니므로 오탐이면 안 된다.
P="$T/decexample"; new_project "$P"
cat > "$P/.claude/rules/requirements.md" <<'EOF'
# 요구사항
형식은 아래와 같다.
```markdown
- **관련**: FR-09, DEC-012
```
자세한 규약은 `DEC-012` 표기를 참고한다.
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'DEC-012' && fail "형식 예시·백틱 DEC 표기를 오탐" || pass "형식 예시·백틱 DEC 표기 제외"

# ── 복사 직후 상태 회귀 — 템플릿 자신이 자기 검사를 통과하는가 ────────────
# greenfield 절차는 _skeleton-README.md를 지운 뒤 check-docs를 돌리라고 지시한다.
# 배포되는 .claude/CLAUDE.md의 "규약을 설명하는 산문"이 플레이스홀더로 오인되면,
# 대상 프로젝트는 린터를 달래려고 문서 품질을 깎게 된다. 그 구간을 그대로 검사한다.
P="$T/asshipped"; new_project "$P"
awk '/^## 산출물 흐름/{f=1} f' "$HERE/../.claude/CLAUDE.md" > "$P/.claude/CLAUDE.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'CLAUDE.md' \
  && fail "배포 CLAUDE.md의 규약 산문을 오탐: $(echo "$OUT" | grep -A3 'CLAUDE.md' | head -4 | tr '\n' ' ')" \
  || pass "배포 CLAUDE.md의 규약 산문 오탐 없음(복사 직후 상태)"

# ── git 픽스처 헬퍼 ───────────────────────────────────────────────────────
# 전역 git 설정에 의존하지 않도록 커밋마다 user 를 인라인으로 준다(CI 환경 비의존).
gcommit() { (cd "$1" && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "$2"); }
git_project() {
  d="$1"; new_project "$d"
  (cd "$d" && git init -q 2>/dev/null && git -c user.email=t@t -c user.name=t \
     commit -q --allow-empty -m 'chore: init')
}
# changelog 를 커밋해 기준점을 만든다(이후 커밋이 스테일 카운트 대상).
commit_changelog() {
  d="$1"
  printf '# Changelog\n\n## [Unreleased]\n' > "$d/.claude/workspace/changelog.md"
  (cd "$d" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m 'docs: changelog')
}
strict_code() { (cd "$1" && bash scripts/check-docs.sh --strict >/dev/null 2>&1); echo "$?"; }

# ── §5 changelog 스테일 검사 ──────────────────────────────────────────────
P="$T/stale3"; git_project "$P"; commit_changelog "$P"
gcommit "$P" 'feat: 하나'; gcommit "$P" 'fix(auth): 둘'; gcommit "$P" 'feat!: 셋'
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'changelog' && pass "feat/fix 3건 누적 시 changelog 스테일 경고" \
  || fail "스테일 3건을 놓침"

P="$T/stale2"; git_project "$P"; commit_changelog "$P"
gcommit "$P" 'feat: 하나'; gcommit "$P" 'fix: 둘'
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'changelog' && fail "경계값 2건에서 오탐" || pass "feat/fix 2건은 유예(경계값)"

P="$T/staletype"; git_project "$P"; commit_changelog "$P"
for m in 'docs: 하나' 'chore: 둘' 'refactor: 셋' 'test: 넷' 'perf: 다섯'; do gcommit "$P" "$m"; done
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'changelog' && fail "docs/chore/refactor/test/perf 를 오탐" \
  || pass "feat/fix 외 타입은 카운트하지 않음"

# changelog 를 지금 고치는 중(워킹트리 변경)이면 스테일이 아니다.
# 커밋 전까지 계속 경고하면 로컬 Stop hook 이 작업 내내 시끄러워진다.
P="$T/staledirty"; git_project "$P"; commit_changelog "$P"
gcommit "$P" 'feat: 하나'; gcommit "$P" 'fix: 둘'; gcommit "$P" 'feat: 셋'
printf '# Changelog\n\n## [Unreleased]\n- **feat**: 방금 반영한 항목\n' > "$P/.claude/workspace/changelog.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'changelog' && fail "changelog 를 고치는 중인데 스테일 경고" \
  || pass "changelog 워킹트리 변경 중이면 스테일 아님"

# git 레포가 아니면 히스토리 판정이 성립하지 않는다 → 경고가 아니라 조용한 스킵.
P="$T/nogit"; new_project "$P"
printf '# Changelog\n\n## [Unreleased]\n' > "$P/.claude/workspace/changelog.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'changelog' && fail "git 레포가 아닌데 스테일 경고" || pass "git 레포 아니면 스테일 검사 스킵"
[ "$(strict_code "$P")" -eq 0 ] && pass "git 레포 아니어도 --strict 통과" || fail "git 아닌데 --strict 실패"

# ── §6 버전 3자 일치 검사 ─────────────────────────────────────────────────
mk_version_project() {
  d="$1"; git_project "$d"
  printf '%s\n' "$2" > "$d/VERSION"
  printf '# Changelog\n\n## [Unreleased]\n\n## v%s (2026-01-01)\n- 초기\n' "$3" \
    > "$d/.claude/workspace/changelog.md"
  (cd "$d" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m 'docs: changelog')
}

P="$T/vermismatch"; mk_version_project "$P" "0.3.0" "0.2.0"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '0.3.0' && pass "SoT ↔ changelog 최신 릴리즈 불일치 경고" \
  || fail "버전 불일치를 놓침"

P="$T/verinvert"; mk_version_project "$P" "0.3.0" "0.3.0"
(cd "$P" && git tag v0.4.0)
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'v0.4.0\|0.4.0' && pass "tag 가 SoT 보다 앞선 역전 경고" || fail "버전 역전을 놓침"

# /release 는 파일만 고치고 태그는 사람이 단다. 그 사이 구간을 경고로 만들면
# 릴리즈할 때마다 빨간불이 뜨고 CI(PR 브랜치엔 태그 없음)가 상시 실패한다.
P="$T/vernotag"; mk_version_project "$P" "0.3.0" "0.3.0"
[ "$(strict_code "$P")" -eq 0 ] && pass "태그 미달성은 안내만 — --strict 통과" \
  || fail "태그 없다고 --strict 실패(오탐)"

P="$T/nosot"; git_project "$P"
printf '# Changelog\n\n## v9.9.9 (2026-01-01)\n' > "$P/.claude/workspace/changelog.md"
(cd "$P" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m 'docs: changelog')
[ "$(strict_code "$P")" -eq 0 ] && pass "SoT 없으면 버전 검사 자체를 건너뜀" || fail "SoT 없는데 버전 경고"

P="$T/policynone"; mk_version_project "$P" "0.3.0" "0.2.0"
printf '# 명령어\n\n## 버전 정책\nversion-policy: none\n' > "$P/.claude/rules/commands.md"
[ "$(strict_code "$P")" -eq 0 ] && pass "version-policy: none 이면 버전 검사 OFF" \
  || fail "policy none 인데 버전 경고"

P="$T/badformat"; mk_version_project "$P" "0.3" "0.3"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '0.3' && pass "semver 형식이 아닌 SoT 경고" || fail "형식 위반을 놓침"

# ── §7 BACKLOG 상태 정합성 ────────────────────────────────────────────────
# 완료 체크박스가 닫혔는데 BACKLOG 표만 낡는 실패를 잡는다(readme-sync 갱신 묶음 3번).
P="$T/backlog-b"; new_project "$P"
cat > "$P/.claude/workspace/todo.md" <<'EOF'
# TODO
## ✅ 완료
- [x] flexContainer 구현 (BACKLOG-005) — 완료: 2026-08-01

## 백로그 (BACKLOG)
| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-005 | flexContainer 구현 | 🔄 진행중 | |
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-005' \
  && pass "§7-B 완료 체크박스 ↔ 표 상태 불일치 검출" || fail "§7-B 자기모순을 놓침"

# 표가 없으면(= BACKLOG를 쓰지 않는 프로젝트) 검사 자체를 건너뛴다.
P="$T/backlog-skip"; new_project "$P"
printf '%s\n' '# TODO' '- [x] flexContainer 구현 (BACKLOG-005)' > "$P/.claude/workspace/todo.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-005' \
  && fail "BACKLOG 표가 없는데 경고(스킵 조건 미동작)" || pass "BACKLOG 표 없으면 §7 스킵"

if [ "$FAIL" -eq 0 ]; then echo "✅ test-check-docs: 전부 통과"; exit 0; fi
echo "❌ test-check-docs: 실패"; exit 1
