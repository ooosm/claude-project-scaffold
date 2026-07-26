#!/usr/bin/env bash
# 문서 정합성 검사 — 방법론 문서의 기계적 오류를 잡는다 (규칙 준수의 최소 강제 수단).
#   1) 플레이스홀더 잔존   : 실문서에 [한글 플레이스홀더]·VAR_NAME·YYYY-MM-DD·ID 리터럴이 남아 있는지
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

# 플레이스홀더 검출(행번호 보존).
#   - ```mermaid 펜스는 노드 라벨이 비-ASCII 대괄호(`[집계 엔진]`)라 플레이스홀더와 구분 불가 →
#     빈 줄로 치환해 검사에서 제외(다른 코드펜스의 `[설치 명령]` 같은 플레이스홀더는 남겨 검출).
#   - 검출: (1) 비-ASCII 문자를 포함한 대괄호 (2) VAR_NAME (3) YYYY-MM-DD/HH:MM (4) ID 리터럴(-NNN/-NN/-N-M).
#   - 제외: 마크다운 링크/이미지(`](`)·각주(`[^`).
#   원하는 스켈레톤 플레이스홀더는 전부 한글(비-ASCII)을 포함하므로, 체크박스([ ]/[x])·
#   [Unreleased]·코드 인덱싱(arr[idx]) 등 ASCII 정상 표기는 자연히 제외된다.
#   `[^ -~]`(0x20~0x7E 밖=비-ASCII 바이트) + LC_ALL=C 로 로케일 독립(비-UTF-8 CI에서도 동일 동작).
scan_placeholders() {
  awk '
    /^[[:space:]]*```mermaid/ {inm=1; print ""; next}
    inm && /^[[:space:]]*```/  {inm=0; print ""; next}
    inm {print ""; next}
    {print}
  ' "$1" \
  | LC_ALL=C grep -nE '\[[^]]*[^ -~][^]]*\]|VAR_NAME|YYYY-MM-DD|HH:MM|[A-Z]{2,}-(NNN|NN|N-M)' \
  | LC_ALL=C grep -vE '\]\(|\[\^'
}

# ── 1. 플레이스홀더 잔존 검사 ─────────────────────────────────────────────
# 템플릿(_TEMPLATE-*, _skeleton-*)과 룰(형식 예시 포함)은 플레이스홀더가 정상이므로 제외.
#
# 템플릿 자기감지: 루트에 _skeleton-README.md 가 있으면 = 스캐폴드 템플릿 레포 자신이다
# (골격의 플레이스홀더는 정상). 대상 프로젝트는 부트스트랩 때 이 파일을 지우므로,
# 그때부터 플레이스홀더 검사가 자동으로 켜진다. 구조 검사(2·3)는 두 경우 모두 수행한다.
if [ -f "_skeleton-README.md" ]; then
  echo "ℹ️  스캐폴드 템플릿 레포로 감지(_skeleton-README.md 존재) — 플레이스홀더 검사 생략"
else
  REAL_DOCS=""
  for f in .claude/CLAUDE.md CLAUDE.md README.md docs/user-guide.md docs/how-it-works.md \
           .claude/docs/*.md .claude/workspace/*.md; do
    [ -f "$f" ] && REAL_DOCS="$REAL_DOCS $f"
  done

  for f in $REAL_DOCS; do
    all=$(scan_placeholders "$f")
    if [ -n "$all" ]; then
      n=$(printf '%s\n' "$all" | wc -l | tr -d ' ')
      warn "플레이스홀더 잔존: $f (${n}건)"
      printf '%s\n' "$all" | head -5 | sed 's/^/      /'
      [ "$n" -gt 5 ] && echo "      … 외 $((n - 5))건"
    fi
  done
fi

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
