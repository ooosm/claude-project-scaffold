#!/usr/bin/env bash
# 새 작업 사이클의 spec/plan 골격을 오늘 날짜로 생성한다(brainstorming→writing-plans 게이트 진입점).
# 사용: scripts/new-feature.sh "<기능-slug>"   (예: user-auth)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SLUG="${1:-untitled}"
DATE="$(date +%F)"

SPEC_TPL="$ROOT/docs/superpowers/specs/_TEMPLATE-design.md"
PLAN_TPL="$ROOT/docs/superpowers/plans/_TEMPLATE-plan.md"
SPEC="$ROOT/docs/superpowers/specs/$DATE-$SLUG-design.md"
PLAN="$ROOT/docs/superpowers/plans/$DATE-$SLUG.md"

[ -f "$SPEC_TPL" ] || { echo "spec 템플릿 없음: $SPEC_TPL" >&2; exit 1; }
[ -f "$PLAN_TPL" ] || { echo "plan 템플릿 없음: $PLAN_TPL" >&2; exit 1; }
[ -e "$SPEC" ] && { echo "이미 존재: $SPEC (덮어쓰지 않음)" >&2; exit 1; }
[ -e "$PLAN" ] && { echo "이미 존재: $PLAN (덮어쓰지 않음)" >&2; exit 1; }

cp "$SPEC_TPL" "$SPEC"
cp "$PLAN_TPL" "$PLAN"

# 날짜·slug 플레이스홀더 치환 (sed -i.bak : BSD/GNU 양쪽 호환)
# <slug> 를 먼저 치환한 뒤 날짜를 치환한다(순서가 바뀌면 spec 경로 패턴이 깨진다).
sed -i.bak "s/<slug>/$SLUG/g; s/YYYY-MM-DD/$DATE/g" "$SPEC" "$PLAN"
rm -f "$SPEC.bak" "$PLAN.bak"

echo "✅ 작업 사이클 골격 생성:"
echo "   spec: docs/superpowers/specs/$DATE-$SLUG-design.md"
echo "   plan: docs/superpowers/plans/$DATE-$SLUG.md"
echo "   → 다음: brainstorming으로 spec을 채우고(UI면 목업 게이트), writing-plans로 plan을 분해하세요."
