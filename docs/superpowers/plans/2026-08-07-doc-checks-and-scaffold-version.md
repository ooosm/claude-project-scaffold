---
related: [BACKLOG-004, DEC-017, DEC-018, DEC-019]
spec: docs/superpowers/specs/2026-08-07-doc-checks-and-scaffold-version-design.md
status: draft
date: 2026-08-07
---

# 구현 계획: 대외 문서 검사 2종(§8·§9) + 스캐폴드 버전 스탬프

> spec: `docs/superpowers/specs/2026-08-07-doc-checks-and-scaffold-version-design.md`
> 결정: DEC-017(§8) · DEC-018(§9) · DEC-019(스탬프)

## 개요

파생 프로젝트 요청 3건을 한 사이클로 처리한다 — §9(필수 문서 존재) + 픽스처 보강,
§8(README 버전 반영), 버전 스탬프 + §10(스탬프 일치). 마지막에 v0.2.0을 끊는다.

## 전역 제약

- **셸**: bash 3.2 호환. GNU 전용 옵션 금지. 경고는 반드시 기존 `warn()`.
- **스킵 우선**: 판정 재료가 없으면 경고가 아니라 스킵(§5·§6의 기존 원칙).
- **템플릿 레포 자기감지**: `_skeleton-README.md` 존재 여부로 판정한다(§1과 동일한 신호).
  §9는 자기감지 `else` 안, §10과 스탬프 쓰기는 자기감지 `if` 안이다 — **방향이 반대**이므로
  헷갈리지 말 것.
- **테스트**: 모든 픽스처는 `new_project()`를 거친다(`git_project`·`mk_version_project`도
  내부에서 호출). 첫 인라인 트리(`$T` 루트)만 별도다.

## 변경 파일

| 파일 | 변경 |
|------|------|
| `scripts/check-docs.sh` | §9(필수 문서, §1 else 안) · §8(README 버전) · §10(스탬프 일치) |
| `scripts/lib-version.sh` | `changelog_previous_release()` · `previous_git_tag()` 추가 |
| `scripts/new-release.sh` | 템플릿 레포에서만 스탬프 동시 기록 + 결과 안내 한 줄 |
| `scripts/test-check-docs.sh` | 픽스처 보강 + "지우면 통과"→"교체하면 통과" + 케이스 8건 |
| `.claude/SCAFFOLD-VERSION` | 신규(한 줄) |
| `.claude/rules/commands.md`·`project-init.md`·`README.md` | 검사 목록·구조·스탬프 설명 |
| `.claude/workspace/{todo,changelog}.md` | BACKLOG-004 등록·마감, `[Unreleased]` 기록 |

---

## Task 1: §9 필수 문서 존재 검사 + 픽스처 보강

**파일**
- 수정: `scripts/check-docs.sh` (§1의 `else` 블록 맨 앞)
- 수정: `scripts/test-check-docs.sh` (픽스처 2곳 + 기존 케이스 1건 전환 + 신규 케이스 2건)

**이 태스크가 만드는 것**: 이후 모든 태스크의 픽스처가 `README.md`·`CLAUDE.md`를 갖는다.

- [ ] **Step 1: 픽스처를 먼저 고친다 (테스트가 성립할 토대)**

`new_project()`의 `printf` 3줄 **뒤**에 추가:

```bash
  printf '%s\n' '# 마이프로젝트' '테스트용 최소 README.' > "$d/README.md"
  printf '%s\n' '# 마이프로젝트' '테스트용 최소 CLAUDE.md.' > "$d/CLAUDE.md"
```

첫 인라인 트리(`cp "$HERE/check-docs.sh" "$T/scripts/check-docs.sh"` 다음 줄)에 추가:

```bash
printf '%s\n' '# 마이프로젝트' '테스트용 최소 README.' > "$T/README.md"
printf '%s\n' '# 마이프로젝트' '테스트용 최소 CLAUDE.md.' > "$T/CLAUDE.md"
```

- [ ] **Step 2: "지우면 통과" 케이스를 "교체하면 통과"로 바꾼다**

기존:

```bash
# 클린 전용(더티 제거) → exit 0 이어야
rm -f "$T/docs/how-it-works.md"
(cd "$T" && bash scripts/check-docs.sh --strict >/dev/null 2>&1)
[ "$?" -eq 0 ] && pass "클린 문서만 남으면 --strict 통과" || fail "클린 문서인데 --strict 실패"
```

교체:

```bash
# 클린 전용(더티를 깨끗한 내용으로 교체) → exit 0 이어야.
# 파일을 지우지 않는 이유: §9 필수 문서 검사와 충돌하지 않으면서 의도(클린 문서만 남으면
# 통과)는 그대로 검증하기 위함이다.
cat > "$T/docs/how-it-works.md" <<'EOF'
# 동작 원리 — 마이프로젝트
요청이 들어오면 라우터가 핸들러를 고르고, 핸들러가 저장소를 호출한다.
EOF
(cd "$T" && bash scripts/check-docs.sh --strict >/dev/null 2>&1)
[ "$?" -eq 0 ] && pass "더티 문서를 클린으로 교체하면 --strict 통과" || fail "클린 문서인데 --strict 실패"
```

- [ ] **Step 3: 실패하는 테스트를 쓴다**

파일 끝 결과 집계 **앞**에 추가:

```bash
# ── §9 필수 납품 문서 존재 ────────────────────────────────────────────────
# REAL_DOCS 는 glob 이라 파일이 없으면 조용히 통과한다 — "미작성"은 잡아도 "없음"은 못 잡았다.
P="$T/reqdocs"; new_project "$P"
rm -f "$P/README.md" "$P/CLAUDE.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'README.md' && echo "$OUT" | grep -q 'CLAUDE.md' \
  && pass "§9 필수 문서 누락을 각 파일명으로 검출" || fail "§9 누락을 놓침"
[ "$(strict_code "$P")" -eq 1 ] && pass "§9 누락이면 --strict exit 1" || fail "§9 누락인데 --strict 통과"

# CLAUDE.md 는 루트/.claude 어느 한쪽만 있어도 된다 — 스캐폴드 자신이 .claude/CLAUDE.md 만 쓴다.
P="$T/reqdocs-dotclaude"; new_project "$P"
mv "$P/CLAUDE.md" "$P/.claude/CLAUDE.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '필수 문서 누락' \
  && fail ".claude/CLAUDE.md 만 있는데 누락으로 오탐" || pass "§9 CLAUDE.md 는 두 위치 중 하나면 통과"
```

- [ ] **Step 4: 테스트가 실패하는지 확인한다**

```bash
bash scripts/test-check-docs.sh
```
기대: `✗ §9 누락을 놓침` · `✗ §9 누락인데 --strict 통과`. 나머지는 전부 `✓`
(픽스처에 README·CLAUDE.md가 늘었어도 기존 단언이 깨지지 않아야 한다 — 깨지면 그 자체가 버그다).

- [ ] **Step 5: §9를 구현한다**

`check-docs.sh` §1의 `else` 블록 맨 앞(`REAL_DOCS=""` 바로 위)에 삽입:

```bash
  # ── 9. 필수 납품 문서 존재 검사 ────────────────────────────────────────
  # 아래 REAL_DOCS 는 glob 이라 **파일이 아예 없으면 조용히 건너뛴다** — "문서가 미작성"은
  # 잡아도 "문서가 없음"은 못 잡는다. 부트스트랩 직후나 실수로 지운 경우가 그대로 통과했다.
  # CLAUDE.md 는 루트/`.claude/` 어느 쪽이든 하나면 된다(project-init 이 두 위치를 모두 인정).
  # user-guide·how-it-works 를 필수로 두지 않는 이유는 DEC-009 의 lazy 생성 규정 때문이다.
  [ -f "README.md" ] || warn "필수 문서 누락: README.md"
  [ -f "CLAUDE.md" ] || [ -f ".claude/CLAUDE.md" ] \
    || warn "필수 문서 누락: CLAUDE.md (루트 또는 .claude/ 중 한 곳에 필요)"

```

- [ ] **Step 6: 통과 확인 + 커밋**

```bash
bash scripts/test-check-docs.sh && bash scripts/check-docs.sh
git add scripts/check-docs.sh scripts/test-check-docs.sh
git commit -m "feat: check-docs §9 필수 납품 문서 존재 검사 + 테스트 픽스처 보강"
```

---

## Task 2: §8 README 버전 반영 검사

**파일**
- 수정: `scripts/lib-version.sh` (조회 함수 2개 추가)
- 수정: `scripts/check-docs.sh` (§7 뒤, 결과 집계 앞)
- 수정: `scripts/test-check-docs.sh`

**소비**: Task 1의 픽스처(README.md 존재), 기존 `read_version_policy`·`sot_version`·
`git_history_usable`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

```bash
# ── §8 릴리즈 버전의 README 반영 ──────────────────────────────────────────
# mobius4 v4.10.0 사고: SoT·changelog·tag 는 다 맞았는데 README 버전 표에 행이 없었다.
P="$T/readmever"; mk_version_project "$P" "0.3.0" "0.2.0"
printf '%s\n' '# 마이프로젝트' '' '| 버전 | 날짜 |' '|---|---|' '| 0.2.0 | 2026-01-01 |' \
  > "$P/README.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '0.3.0' \
  && pass "§8 직전 버전만 README 에 있으면 경고" || fail "§8 README 미반영을 놓침"

# 현재 버전을 적어 넣으면 경고가 사라진다(자기해소형).
printf '%s\n' '# 마이프로젝트' '' '| 버전 | 날짜 |' '|---|---|' '| 0.3.0 | 2026-02-01 |' \
  '| 0.2.0 | 2026-01-01 |' > "$P/README.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'README 버전 미반영' \
  && fail "현재 버전이 README 에 있는데 경고" || pass "§8 현재 버전이 있으면 조용"

# README 에 버전을 적지 않는 프로젝트는 검사 자체를 건너뛴다(오탐 0).
P="$T/readmever-none"; mk_version_project "$P" "0.3.0" "0.2.0"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'README 버전 미반영' \
  && fail "버전을 안 적는 README 에 오탐" || pass "§8 직전 버전도 없으면 스킵"

# changelog 가 없어도 git tag 로 직전 버전을 찾는다(mobius4 는 루트 CHANGELOG.md 를 쓴다).
P="$T/readmever-tag"; git_project "$P"
printf '%s\n' '0.3.0' > "$P/VERSION"
printf '%s\n' '# 마이프로젝트' '지원 버전: 0.2.0' > "$P/README.md"
(cd "$P" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m 'chore: v0.2.0' \
   && git tag v0.2.0)
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '0.3.0' \
  && pass "§8 changelog 없으면 git tag 로 폴백" || fail "§8 태그 폴백이 동작하지 않음"

# 버전 문자열 경계 — 14.9.0 은 4.9.0 의 포함이 아니다.
P="$T/readmever-boundary"; mk_version_project "$P" "0.3.0" "0.2.0"
printf '%s\n' '# 마이프로젝트' '빌드 번호 10.2.0 참고' > "$P/README.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'README 버전 미반영' \
  && fail "10.2.0 을 0.2.0 으로 오인" || pass "§8 버전 문자열 경계 구분"

# version-policy: none 이면 §6 과 동일하게 검사하지 않는다.
P="$T/readmever-policy"; mk_version_project "$P" "0.3.0" "0.2.0"
printf '%s\n' '# 마이프로젝트' '버전 0.2.0' > "$P/README.md"
printf '# 명령어\n\n## 버전 정책\nversion-policy: none\n' > "$P/.claude/rules/commands.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'README 버전 미반영' \
  && fail "policy none 인데 §8 경고" || pass "§8 version-policy: none 이면 OFF"
```

- [ ] **Step 2: 실패 확인**

```bash
bash scripts/test-check-docs.sh
```
기대: `✗ §8 README 미반영을 놓침` · `✗ §8 태그 폴백이 동작하지 않음`
(나머지 4건은 §8이 없으면 자동 통과 — 구현 후에도 계속 통과해야 의미가 있다)

- [ ] **Step 3: `lib-version.sh`에 조회 함수 2개를 추가한다**

`changelog_latest_release()` 정의 **뒤**에:

```bash
# changelog 릴리즈 헤딩 중 $1(현재 버전)이 아닌 첫 번째. 없으면 빈 문자열.
# §8 이 "직전 릴리즈"를 필요로 한다 — latest 는 대개 현재 버전이라 비교 대상이 못 된다.
changelog_previous_release() {
  [ -f "$CHANGELOG_PATH" ] || return 0
  grep -E '^##[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+' "$CHANGELOG_PATH" \
    | sed -E 's/^##[[:space:]]+v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/' \
    | grep -vx "${1:-}" | head -1
}
```

`latest_git_tag()` 정의 **뒤**에:

```bash
# semver 태그 중 $1(현재 버전)을 제외한 최댓값. 없으면 빈 문자열.
# changelog 를 표준 경로에 두지 않는 레포(루트 CHANGELOG.md 등)를 위한 §8 폴백이다.
previous_git_tag() {
  git_history_usable || return 0
  git tag -l 'v*' 2>/dev/null \
    | sed -E 's/^v//' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | grep -vx "${1:-}" \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1
}
```

- [ ] **Step 4: §8을 구현한다**

`check-docs.sh` §7 블록 뒤, `# ── 결과 ──` 앞에 삽입:

```bash
# ── 8. 릴리즈 버전의 README 반영 검사 ────────────────────────────────────
# §6 은 SoT ↔ changelog ↔ tag 셋만 본다. 그 셋이 다 맞아도 README 가 낡을 수 있고, 실제로
# 파괴적 변경을 알리는 버전 표가 비어 있는 채로 릴리즈된 적이 있다(DEC-017).
#
# 판정: **직전 릴리즈가 README 에 있는데 현재 버전이 없으면** 경고. 둘 다 없으면 그 레포는
# README 에 버전을 적지 않는 것이므로 스킵한다 — 설정 없이 습관을 자동 감지한다.
# 한계: 문자열 포함만 보므로 행이 있어도 내용이 비면 못 잡고, 첫 릴리즈는 비교 대상이 없다.
ver_in_file() {  # $1=버전 $2=파일. 10.2.0 을 0.2.0 으로 오인하지 않도록 경계를 본다.
  esc=$(printf '%s' "$1" | sed 's/\./\\./g')
  grep -qE "(^|[^0-9.])${esc}([^0-9.]|\$)" "$2"
}

if command -v detect_version_sot >/dev/null 2>&1 && [ -f "README.md" ]; then
  POLICY8=$(read_version_policy)
  SOT8=$(sot_version)
  if [ "$POLICY8" != "none" ] && [ -n "$SOT8" ]; then
    PREV8=$(changelog_previous_release "$SOT8")
    [ -z "$PREV8" ] && PREV8=$(previous_git_tag "$SOT8")
    if [ -n "$PREV8" ] && ver_in_file "$PREV8" README.md && ! ver_in_file "$SOT8" README.md; then
      warn "README 버전 미반영: 직전 릴리즈 '$PREV8' 는 README.md 에 있는데 현재 '$SOT8' 이 없습니다 — 버전 표·기능 목록·업그레이드 안내를 확인하세요"
    fi
  fi
fi
```

- [ ] **Step 5: 통과 확인 + 커밋**

```bash
bash scripts/test-check-docs.sh && bash scripts/check-docs.sh
git add scripts/lib-version.sh scripts/check-docs.sh scripts/test-check-docs.sh
git commit -m "feat: check-docs §8 릴리즈 버전의 README 반영 검사"
```

---

## Task 3: 버전 스탬프 + §10 일치 검사 + `/release` 연동

**파일**
- 생성: `.claude/SCAFFOLD-VERSION`
- 수정: `scripts/check-docs.sh` (§8 뒤), `scripts/new-release.sh`, `scripts/test-check-docs.sh`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

```bash
# ── §10 스캐폴드 버전 스탬프 일치 ─────────────────────────────────────────
# 스탬프는 파생 레포가 "내가 받은 버전"을 아는 유일한 근거다. 업스트림에서 VERSION 과
# 어긋나면 그 순간부터 거짓말이 되므로 템플릿 레포에서만 일치를 검사한다.
P="$T/stamp"; new_project "$P"
printf '%s\n' '0.1.0' > "$P/VERSION"
printf '%s\n' '0.9.9' > "$P/.claude/SCAFFOLD-VERSION"
printf '%s\n' '# 스켈레톤' > "$P/_skeleton-README.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '0.9.9' \
  && pass "§10 스탬프 ↔ VERSION 불일치 검출" || fail "§10 스탬프 불일치를 놓침"

# 파생 레포(스켈레톤 없음)에서는 두 값이 다른 게 정상이다 — 검사하지 않는다.
P="$T/stamp-derived"; new_project "$P"
printf '%s\n' '4.10.0' > "$P/VERSION"
printf '%s\n' '0.2.0' > "$P/.claude/SCAFFOLD-VERSION"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q '스탬프' \
  && fail "파생 레포에서 스탬프 불일치를 경고(오탐)" || pass "§10 파생 레포에서는 검사 안 함"
```

- [ ] **Step 2: 실패 확인**

```bash
bash scripts/test-check-docs.sh
```
기대: `✗ §10 스탬프 불일치를 놓침`

- [ ] **Step 3: 스탬프 파일을 만든다**

```bash
printf '%s\n' '0.1.0' > .claude/SCAFFOLD-VERSION
```

> 지금은 현재 릴리즈와 같은 0.1.0으로 시작한다. Task 5의 `/release minor`가 둘을 함께
> 0.2.0으로 올린다.

- [ ] **Step 4: §10을 구현한다**

`check-docs.sh` §8 뒤에 삽입:

```bash
# ── 10. 스캐폴드 버전 스탬프 일치 검사 (템플릿 레포 한정) ────────────────
# .claude/SCAFFOLD-VERSION 은 `.claude/` 와 함께 복사되어 파생 레포에 따라간다. 파생 레포에서
# 이 값과 VERSION 이 다른 것은 **정상**이다(스탬프=받아온 버전, VERSION=자기 버전).
# 그래서 일치 검사는 업스트림(_skeleton-README.md 가 있는 템플릿 레포)에서만 한다.
SCAFFOLD_STAMP=".claude/SCAFFOLD-VERSION"
if [ -f "_skeleton-README.md" ] && [ -f "$SCAFFOLD_STAMP" ] && [ -f "VERSION" ]; then
  s=$(head -1 "$SCAFFOLD_STAMP" | tr -d '[:space:]')
  v=$(head -1 VERSION | tr -d '[:space:]')
  [ "$s" = "$v" ] \
    || warn "스탬프 불일치: $SCAFFOLD_STAMP 는 '$s' 인데 VERSION 은 '$v' — /release 로 함께 갱신하세요"
fi
```

- [ ] **Step 5: `/release`가 스탬프를 함께 쓰게 한다**

`new-release.sh`의 "쓰기 후 재검증" 블록(`GOT="$(sot_version)"` … `die` 끝) **뒤**에 삽입:

```bash
# ── 2-1. 스캐폴드 버전 스탬프 ────────────────────────────────────────────
# **템플릿 레포에서만** 쓴다. 파생 레포에서 이걸 덮으면 "받아온 스캐폴드 버전"이 자기 버전으로
# 바뀌어 스탬프가 거짓말이 된다 — 스탬프의 존재 이유가 사라진다.
STAMP_UPDATED="no"
if [ -f "_skeleton-README.md" ] && [ -f ".claude/SCAFFOLD-VERSION" ]; then
  printf '%s\n' "$NEXT" > .claude/SCAFFOLD-VERSION
  STAMP_UPDATED="yes"
fi
```

결과 안내(`printf '   %-28s [Unreleased] 마감...` 다음 줄)에 추가:

```bash
[ "$STAMP_UPDATED" = "yes" ] && printf '   %-28s 스탬프 갱신\n' ".claude/SCAFFOLD-VERSION"
```

- [ ] **Step 6: 통과 확인 + 커밋**

```bash
bash scripts/test-check-docs.sh && bash scripts/check-docs.sh
git add scripts/check-docs.sh scripts/new-release.sh scripts/test-check-docs.sh .claude/SCAFFOLD-VERSION
git commit -m "feat: 스캐폴드 버전 스탬프(.claude/SCAFFOLD-VERSION) + §10 일치 검사"
```

---

## Task 4: 문서 반영

**파일**: `.claude/rules/commands.md`, `.claude/rules/project-init.md`, `README.md`,
`.claude/workspace/todo.md`, `.claude/workspace/changelog.md`

- [ ] **Step 1: `commands.md` 검사 설명 갱신**

```
bash scripts/check-docs.sh          # 플레이스홀더·필수문서·REQ/FR·DEC·changelog·버전 3자 일치·BACKLOG·README 버전·스탬프 (경고만, exit 0)
```

- [ ] **Step 2: `project-init.md` 디렉토리 구조에 스탬프 추가**

`├── .claude/` 블록의 `├── settings.json` **위**에:

```
    ├── SCAFFOLD-VERSION          ← 이 프로젝트가 받아온 스캐폴드 버전(파생 레포는 손대지 않음)
```

- [ ] **Step 3: `README.md` 갱신**

- 디렉토리 트리의 `check-docs.sh` 주석에 `·필수문서·README버전` 추가
- `.claude/` 파일 semantics 표에 `SCAFFOLD-VERSION` 행 추가
- **"스캐폴드 버전 확인" 안내를 새로 넣는다** — 파생 레포에서
  `cat .claude/SCAFFOLD-VERSION` 과 업스트림 `VERSION`을 비교하고, 차이는 업스트림
  README Changelog에서 확인한다는 3줄.

- [ ] **Step 4: `todo.md`에 BACKLOG-004 등록·마감, `changelog.md` `[Unreleased]` 기록**

- [ ] **Step 5: 검증 + 커밋**

```bash
bash scripts/check-docs.sh --strict
git add -A && git commit -m "docs: §8·§9·§10 + 스탬프 문서 반영"
```

---

## Task 5: v0.2.0 릴리즈

- [ ] **Step 1: `[Unreleased]`가 실제 변경을 담고 있는지 확인**(추측 금지 — Task 4 Step 4의 결과)

- [ ] **Step 2: 릴리즈 실행**

```bash
bash scripts/new-release.sh minor
```
기대 출력: `0.1.0 → 0.2.0`, `VERSION`·changelog·README·`.claude/SCAFFOLD-VERSION` 4곳 갱신.

- [ ] **Step 3: README Changelog 골격을 채운다** (`/release`가 넣은 플레이스홀더 제거)

- [ ] **Step 4: 전체 검증**

```bash
bash scripts/test-check-docs.sh
bash scripts/test-new-dec.sh
bash scripts/check-docs.sh --strict
```
기대: 셋 다 exit 0. §10은 스탬프·VERSION이 둘 다 0.2.0이라 조용해야 한다.

- [ ] **Step 5: 커밋 + 태그** — 사용자 승인 후 실행한다.

```bash
git commit -am "chore: release v0.2.0"
git tag v0.2.0
```

> 태그를 다는 이유: §6의 3자 일치가 완성되고, 파생 레포가 `git tag` 로도 버전을 확인할 수
> 있다. 지금까지 v0.1.0 태그가 없어 §6이 안내만 내고 있었다.

## 검증 계획

| 대상 | 방법 |
|------|------|
| §9 정탐·오탐 | 누락 검출 + `--strict` exit 1 + `.claude/CLAUDE.md` 단독 허용 |
| §8 정탐·오탐 | 직전만 있음(정탐) / 현재도 있음 / 둘 다 없음 / 태그 폴백 / 경계(10.2.0) / policy none |
| §10 정탐·오탐 | 템플릿 레포 불일치(정탐) / 파생 레포 불일치(무시) |
| 기존 회귀 | `test-check-docs.sh` 전체 + `test-new-dec.sh` |
| 실사용 | 스캐폴드 자신 `--strict` 초록불, `/release minor` 실행 결과 4곳 확인 |

## 완료 시 갱신 묶음

- [ ] 자동 갱신 묶음 8항목 수행(정본: `.claude/rules/readme-sync.md`)
- [ ] `scripts/check-docs.sh --strict` 통과
- [ ] 의존성 변경 없음

## 범위 밖 (명시적 제외)

- `mobius4`에 check-docs 도입 — 그 레포에는 `scripts/check-docs.sh`가 없다. 도입 여부는
  그쪽 레포의 결정이다.
- `CHANGELOG_PATH` 설정화 — DEC-017 기각 사유 참조. §8은 태그 폴백으로 우회한다.
- 이미 파생된 3개 레포의 스탬프 소급 기입 — 값을 알 수 없다(DEC-019).
