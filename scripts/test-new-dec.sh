#!/usr/bin/env bash
# new-dec.sh 회귀 테스트 — 번호 할당과 append 시 말미 정규화를 검증한다.
# 핵심 회귀: README 부트스트랩 지시("로그를 비우고 DEC-001부터 시작")를 따르면 말미 안내
# 주석이 사라지는데, 그 상태에서 append 하면 새 DEC가 앞 문단에 접합되던 버그.
# CI에서 실행된다.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
FAIL=0
pass() { printf '  ✓ %s\n' "$1"; }
fail() { FAIL=1; printf '  ✗ %s\n' "$1"; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts" "$T/.claude/decisions"
cp "$HERE/new-dec.sh" "$T/scripts/new-dec.sh"
LOG="$T/.claude/decisions/decision-log.md"

# 새 DEC 헤딩 바로 앞 줄을 돌려준다(접합 여부 판정용).
line_before_heading() {
  grep -n "^## $1:" "$LOG" | head -1 | cut -d: -f1 | while read -r n; do
    sed -n "$((n - 1))p" "$LOG"
  done
}

# ── 1. 부트스트랩 상태(말미 안내 주석 없음) — 접합되면 안 된다 ──────────────
cat > "$LOG" <<'EOF'
# 결정 로그

## DEC-001: 첫 결정 (2026-01-01)

**결정**: 무엇.

**성능·향후 영향**: 이 줄이 파일의 마지막 문단이다.
EOF
(cd "$T" && bash scripts/new-dec.sh "두 번째" >/dev/null 2>&1)

grep -q '^## DEC-002:' "$LOG" \
  && pass "안내 주석 없는 로그에도 DEC-002 append" || fail "DEC-002 append 실패"
[ -z "$(line_before_heading DEC-002)" ] \
  && pass "DEC-002 앞에 빈 줄 — 앞 문단에 접합되지 않음" \
  || fail "접합 발생: DEC-002 앞 줄이 '$(line_before_heading DEC-002)'"

# ── 2. 정상 상태(안내 주석 있음) — 기존 동작 회귀 없어야 ────────────────────
(cd "$T" && bash scripts/new-dec.sh "세 번째" >/dev/null 2>&1)
grep -q '^## DEC-003:' "$LOG" && pass "안내 주석 있는 로그에 DEC-003 append" || fail "DEC-003 append 실패"
[ -z "$(line_before_heading DEC-003)" ] \
  && pass "DEC-003 앞에 빈 줄" || fail "DEC-003 접합: 앞 줄이 '$(line_before_heading DEC-003)'"
[ "$(grep -c '다음 결정은 여기 아래에' "$LOG")" -eq 1 ] \
  && pass "말미 안내 주석이 정확히 1개" || fail "안내 주석이 중복되거나 사라짐"

# ── 3. 개행으로 끝나지 않는 파일도 정규화 ──────────────────────────────────
printf '# 결정 로그\n\n## DEC-001: 개행 없이 끝남 (2026-01-01)\n\n**결정**: 마지막 줄에 개행 없음.' > "$LOG"
(cd "$T" && bash scripts/new-dec.sh "개행 없는 말미" >/dev/null 2>&1)
[ -z "$(line_before_heading DEC-002)" ] \
  && pass "개행 없이 끝난 파일도 접합되지 않음" \
  || fail "개행 없는 말미에서 접합: '$(line_before_heading DEC-002)'"

# ── 4. 번호 할당 회귀 — 008/009를 8진수로 오인하지 않는다 ──────────────────
printf '# 결정 로그\n\n## DEC-009: 아홉 번째 (2026-01-01)\n\n**결정**: 무엇.\n' > "$LOG"
(cd "$T" && bash scripts/new-dec.sh "열 번째" >/dev/null 2>&1)
grep -q '^## DEC-010:' "$LOG" && pass "009 다음은 010 (8진수 오인 없음)" || fail "009 다음 번호 오류"

# ── 5. 제목 생략 시에도 동작 ───────────────────────────────────────────────
(cd "$T" && bash scripts/new-dec.sh >/dev/null 2>&1)
grep -q '^## DEC-011:' "$LOG" && pass "제목 생략 시 플레이스홀더로 생성" || fail "제목 생략 시 실패"

if [ "$FAIL" -eq 0 ]; then echo "✅ test-new-dec: 전부 통과"; exit 0; fi
echo "❌ test-new-dec: 실패"; exit 1
