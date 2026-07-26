#!/usr/bin/env bash
# 릴리즈를 끊는다 — 버전 SoT bump + changelog 마감 + README Changelog 골격 삽입.
#
# **git 부작용이 없다.** 커밋·태그는 실행하지 않고 명령어만 출력한다
# (git-workflow 룰: "커밋·푸시는 사용자가 요청할 때"). 되돌리려면 파일을 되돌리면 끝이다.
# new-dec.sh 와 같은 관용구다 — 스크립트는 골격만 만들고, 판단이 필요한 내용
# (README 요약 항목 선별)은 에이전트가 채운다.
#
# 사용: scripts/new-release.sh <major|minor|patch|X.Y.Z>
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib-version.sh
. "$ROOT/scripts/lib-version.sh"

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

KIND="${1:-}"
[ -n "$KIND" ] || die "사용: scripts/new-release.sh <major|minor|patch|X.Y.Z>"

POLICY="$(read_version_policy)"
[ "$POLICY" = "none" ] && die "version-policy: none 입니다 — 이 프로젝트는 버전을 끊지 않습니다.
   릴리즈를 시작하려면 .claude/rules/commands.md 의 '## 버전 정책'을 semver 로 바꾸세요."

SOT_F="$(sot_file)"; CUR="$(sot_version)"
[ -n "$SOT_F" ] || die "버전 SoT 를 찾을 수 없습니다.
   package.json·pyproject.toml·Cargo.toml 중 하나가 있거나, 루트에 VERSION 파일이 필요합니다.
   새로 시작하려면: echo 0.1.0 > VERSION"

# 다음 버전 결정. calver 는 자동 bump 규칙을 지원하지 않으므로 명시 버전을 요구한다.
case "$KIND" in
  major|minor|patch)
    [ "$POLICY" = "calver" ] && die "version-policy: calver 에서는 명시 버전을 주세요 (예: 2026.07.1)"
    NEXT="$(bump_version "$CUR" "$KIND")" || die "현재 버전 '$CUR' 이 semver 가 아니라 bump 할 수 없습니다."
    ;;
  *)
    NEXT="$KIND"
    [ "$POLICY" = "semver" ] && { is_semver "$NEXT" || die "'$NEXT' 은 semver(X.Y.Z) 형식이 아닙니다."; }
    ;;
esac

[ "$NEXT" = "$CUR" ] && die "현재 버전과 같습니다: $CUR"

DATE="$(date +%F)"
[ -f "$CHANGELOG_PATH" ] || die "$CHANGELOG_PATH 가 없습니다."
grep -qE '^##[[:space:]]+\[Unreleased\]' "$CHANGELOG_PATH" \
  || die "$CHANGELOG_PATH 에 '## [Unreleased]' 섹션이 없습니다 — 마감할 대상을 찾을 수 없습니다."

# ── 1. 버전 SoT 기록 ─────────────────────────────────────────────────────
write_toml_version() {  # $1=파일 $2=섹션 $3=새 버전
  awk -v sec="$1" -v ver="$3" '
    $0 ~ "^\\[" sec "\\]" {f=1; print; next}
    /^\[/ {f=0}
    f && /^[[:space:]]*version[[:space:]]*=/ && !done { print "version = \"" ver "\""; done=1; next }
    {print}
  ' "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

case "$SOT_F" in
  VERSION)        printf '%s\n' "$NEXT" > VERSION ;;
  package.json)
    if command -v npm >/dev/null 2>&1; then
      npm version "$NEXT" --no-git-tag-version --allow-same-version >/dev/null
    else
      sed -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")[^\"]*(\")/\1$NEXT\2/" package.json > package.json.tmp \
        && mv package.json.tmp package.json
    fi
    ;;
  pyproject.toml) write_toml_version project "$SOT_F" "$NEXT" ;;
  Cargo.toml)     write_toml_version package "$SOT_F" "$NEXT" ;;
  *)              die "알 수 없는 SoT: $SOT_F" ;;
esac

# ── 2. 쓰기 후 재검증 ────────────────────────────────────────────────────
# toml/json 치환은 본질적으로 취약하다. 쓴 뒤 감지 함수로 다시 읽어 기대값과 대조하면
# 조용히 망가지는 경우가 사라진다 — 틀리면 여기서 시끄럽게 죽는다.
GOT="$(sot_version)"
[ "$GOT" = "$NEXT" ] || die "SoT 기록 검증 실패: $SOT_F 에서 '$NEXT' 를 기대했으나 '$GOT' 을 읽었습니다.
   파일을 확인하고 되돌리세요 (git checkout -- $SOT_F)."

# ── 3. changelog 마감 ────────────────────────────────────────────────────
# [Unreleased] 헤딩을 릴리즈 헤딩으로 바꾸고, 그 위에 새 빈 [Unreleased] 를 넣는다.
# 기존 Unreleased 본문은 그대로 릴리즈 섹션의 내용이 된다.
awk -v v="$NEXT" -v d="$DATE" '
  !done && /^##[[:space:]]+\[Unreleased\]/ {
    print "## [Unreleased]"; print ""; print "## v" v " (" d ")"
    done=1; next
  }
  {print}
' "$CHANGELOG_PATH" > "$CHANGELOG_PATH.tmp" && mv "$CHANGELOG_PATH.tmp" "$CHANGELOG_PATH"

# ── 4. README Changelog 골격 삽입 ────────────────────────────────────────
# 골격의 플레이스홀더는 한글 대괄호라 check-docs §1 이 잡는다 — 요약을 채우지 않으면
# strict CI 가 릴리즈 커밋을 막는다. 새 코드 없이 기존 장치를 재사용하는 지점이다.
README_UPDATED="no"
if [ -f README.md ] && grep -qE '^##[[:space:]]+Changelog' README.md; then
  awk -v v="$NEXT" -v d="$DATE" '
    function emit() { print "### v" v " (" d ")"; print "- **feat**: [사용자 영향 있는 변경 요약]"; print "" }
    /^##[[:space:]]+Changelog/ { print; inc=1; next }
    inc && !done && /^###[[:space:]]/ { emit(); done=1; inc=0; print; next }
    inc && !done && /^##[[:space:]]/  { emit(); done=1; inc=0; print; next }
    {print}
    # Changelog 섹션이 파일 끝일 때(뒤에 다른 헤딩이 없음) — 앞 빈 줄을 먼저 넣는다.
    END { if (inc && !done) { print ""; emit() } }
  ' README.md > README.md.tmp && mv README.md.tmp README.md
  README_UPDATED="yes"
fi

# ── 5. 결과 안내 (git 은 실행하지 않는다) ────────────────────────────────
printf '✅ %s → %s\n' "$CUR" "$NEXT"
printf '   %-28s 버전 SoT 갱신 (재검증 통과)\n' "$SOT_F"
printf '   %-28s [Unreleased] 마감 + 새 [Unreleased] 생성\n' "$CHANGELOG_PATH"
if [ "$README_UPDATED" = "yes" ]; then
  printf '   %-28s v%s 골격 삽입\n' "README.md" "$NEXT"
else
  printf '   %-28s Changelog 섹션이 없어 건너뜀\n' "README.md"
fi
printf '\n→ README Changelog 의 요약 항목을 채우세요(사용자에게 의미 있는 것만).\n'
printf '  플레이스홀더가 남아 있으면 check-docs 가 잡습니다: bash scripts/check-docs.sh\n'
printf '\n→ 확인 후 직접 실행:\n'
printf '     git commit -am "chore: release v%s"\n' "$NEXT"
printf '     git tag v%s\n' "$NEXT"
