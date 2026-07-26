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
  cp "$HERE/check-docs.sh" "$d/scripts/check-docs.sh"
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

if [ "$FAIL" -eq 0 ]; then echo "✅ test-check-docs: 전부 통과"; exit 0; fi
echo "❌ test-check-docs: 실패"; exit 1
