#!/usr/bin/env bash
# 다음 DEC 번호를 원자적으로 할당하고 decision-log에 골격을 append 한다.
# 단일 프로세스가 번호 계산+append를 함께 수행하므로 병렬 세션의 번호 충돌을 예방한다.
# 사용: scripts/new-dec.sh "<결정 제목>"   (제목 생략 시 [제목] 플레이스홀더)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/.claude/decisions/decision-log.md"
[ -f "$LOG" ] || { echo "decision-log.md 없음: $LOG" >&2; exit 1; }

TITLE="${*:-[제목]}"
DATE="$(date +%F)"

MAX="$(grep -oE '^## DEC-[0-9]+' "$LOG" | grep -oE '[0-9]+' | sort -n | tail -1 || true)"
MAX="${MAX:-0}"
N=$((10#$MAX + 1))                       # 10# : 008/009 를 8진수로 오인하지 않게
NNN="$(printf '%03d' "$N")"
NEXT="$(printf '%03d' "$((N + 1))")"

tmp="$(mktemp)"
# 기존 말미 안내 주석 제거(뒤에서 새로 붙인다)
grep -v '^<!-- 다음 결정은 여기 아래에' "$LOG" > "$tmp"

cat >> "$tmp" <<EOF
## DEC-$NNN: $TITLE ($DATE)

**맥락**:

**결정**:

**검토한 대안**:
- ✅ **채택: [안 A]** — 이유:
- ❌ 기각: [안 B] — 이유:

**성능·향후 영향**:

**출처**:

---

<!-- 다음 결정은 여기 아래에 ## DEC-$NEXT 부터 추가 -->
EOF

mv "$tmp" "$LOG"
echo "✅ DEC-$NNN 골격 추가: $LOG"
echo "   → 맥락·결정·검토한 대안(채택+기각 이유)·향후 영향·출처를 채우세요."
