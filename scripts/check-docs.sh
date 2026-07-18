#!/usr/bin/env bash
# 문서 정합성 검사 — 방법론 문서의 기계적 오류를 잡는다 (규칙 준수의 최소 강제 수단).
#   1) 플레이스홀더 잔존   : 실문서에 [프로젝트명]·YYYY-MM-DD 등이 남아 있는지
#   2) REQ/FR 상호 참조     : 요구사항 2분할 문서 간 댕글링 참조
#   3) DEC 번호             : decision-log.md 번호 중복·비단조 증가
# 기본은 경고만(exit 0). --strict 는 경고 발생 시 exit 1 (CI/커밋 전 검사용).
set -u

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
WARN=0

warn() { WARN=$((WARN + 1)); printf '⚠️  %s\n' "$1"; }

# ── 1. 플레이스홀더 잔존 검사 ─────────────────────────────────────────────
# 템플릿(_TEMPLATE-*, _skeleton-*)과 룰(형식 예시 포함)은 플레이스홀더가 정상이므로 제외.
REAL_DOCS=""
for f in .claude/CLAUDE.md CLAUDE.md README.md docs/user-guide.md \
         .claude/docs/*.md .claude/workspace/*.md; do
  [ -f "$f" ] && REAL_DOCS="$REAL_DOCS $f"
done

for f in $REAL_DOCS; do
  hits=$(grep -nE '\[(프로젝트명|개요|스택/호환버전)\]|YYYY-MM-DD' "$f" | head -3)
  if [ -n "$hits" ]; then
    warn "플레이스홀더 잔존: $f"
    printf '%s\n' "$hits" | sed 's/^/      /'
  fi
done

# ── 2. REQ ↔ FR 상호 참조 검사 ────────────────────────────────────────────
IMPL=".claude/docs/01-impl-requirements.md"
USER=".claude/docs/01-user-requirements.md"
if [ -f "$IMPL" ] && [ -f "$USER" ]; then
  # user 문서가 참조하는 REQ가 impl 문서에 정의(### REQ-… 헤딩)돼 있는가
  for req in $(grep -oE 'REQ-[0-9]+-[0-9]+' "$USER" | sort -u); do
    grep -qE "^### ${req}:" "$IMPL" || warn "댕글링 참조: $USER 가 참조한 ${req} 이 $IMPL 에 정의돼 있지 않음"
  done
  # impl 문서가 참조하는 FR가 user 문서에 정의(**FR-NN** 항목)돼 있는가
  for fr in $(grep -oE 'FR-[0-9]+' "$IMPL" | sort -u); do
    grep -qE "\*\*${fr}\*\*" "$USER" || warn "댕글링 참조: $IMPL 가 참조한 ${fr} 이 $USER 에 정의돼 있지 않음"
  done
fi

# ── 3. DEC 번호 중복·단조 증가 검사 ──────────────────────────────────────
DECLOG=".claude/decisions/decision-log.md"
if [ -f "$DECLOG" ]; then
  nums=$(grep -oE '^## DEC-[0-9]+' "$DECLOG" | grep -oE '[0-9]+')
  dup=$(printf '%s\n' "$nums" | sort | uniq -d)
  [ -n "$dup" ] && warn "DEC 번호 중복: $(printf '%s ' $dup)(병렬 세션 충돌 여부 확인)"
  if [ "$(printf '%s\n' "$nums")" != "$(printf '%s\n' "$nums" | sort -n)" ]; then
    warn "DEC 번호가 파일 순서상 단조 증가하지 않음 (append-only 위반 가능성)"
  fi
fi

# ── 결과 ─────────────────────────────────────────────────────────────────
if [ "$WARN" -eq 0 ]; then
  echo "✅ check-docs: 문제 없음"
  exit 0
fi
echo "── check-docs: 경고 ${WARN}건"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
