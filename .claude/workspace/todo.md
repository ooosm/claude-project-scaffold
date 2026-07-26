# TODO — claude-project-scaffold (이 레포 자신의 현황판)
_최종 업데이트: 2026-07-27_

> 실시간 단일 현황판. 작업 시작/완료/블로커 발생 시 즉시 갱신한다.
> 큰 작업 묶음은 `BACKLOG-NNN`으로 식별하고 spec/plan과 상호 참조한다.
>
> ⚠️ **대상 프로젝트에 스캐폴드를 적용할 때**: 아래는 스캐폴드 레포 자신의 항목이므로
> 전부 비우고 대상 프로젝트 현황으로 새로 시작한다(→ README 적용 절차).

## 🔄 진행 중
- (없음)

## ✅ 완료
- [x] 얕은 harness 척추(hook·슬래시 커맨드·CI) — 완료: 2026-07-18
- [x] Git 워크플로 룰(위험도 기반 브랜치 전략) — 완료: 2026-07-19
- [x] 브라운필드 적용 피드백 harness 버그 4건 수정 (DEC-012) — 완료: 2026-07-27
- [x] brownfield 절차 2축 판별 + 경로 충돌 조정 0단계 (DEC-013) — 완료: 2026-07-27
- [x] 버전·changelog 정합성 harness (BACKLOG-002, DEC-011) — 완료: 2026-07-27

## ⏳ 대기 중
- [ ] 글로벌 룰 버전 관리 (BACKLOG-001) — `~/.claude`를 별도 git 레포로 분리·추적

## 🚧 블로커
- (없음)

---

## 백로그 (BACKLOG)

| ID | 제목 | 상태 | spec/plan |
|----|------|------|-----------|
| BACKLOG-001 | 글로벌 룰 버전 관리(`~/.claude` git 추적) | ⏳ 대기 | (미착수) |
| BACKLOG-002 | 버전·changelog 정합성 harness(lib-version·check-docs §5·§6·`/release`) | ✅ 완료 | `2026-07-27-version-release-harness-design.md` |
