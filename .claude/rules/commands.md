# 프로젝트 명령어 (Commands)

> **프로젝트 고유 정보** 파일이다(방법론 룰 8종과 달리 프로젝트마다 내용이 다름).
> 부트스트랩 시 실제 명령어로 채운다. `validation.md`의 각 검증 단계가 이 파일을 참조한다.

## 개발 명령어

| 용도 | 명령어 | 비고 |
|------|--------|------|
| 빌드 | `[예: npm run build]` | 검증 1단계 |
| 단위 테스트 | `[예: npm run test:unit]` | 검증 2단계 |
| 통합 테스트 | `[예: npm run test:integration]` | 검증 3단계 |
| 타입 검사 | `[예: npm run type-check]` | 검증 4단계 |
| 린트 | `[예: npm run lint]` | 검증 4단계 |
| 로컬 실행 | `[예: npm run dev]` | 수동 검증용 |

## 문서 정합성 검사

```bash
bash scripts/check-docs.sh          # 플레이스홀더 잔존·REQ/FR 참조·DEC 번호 검사 (경고만)
bash scripts/check-docs.sh --strict # 경고를 실패(exit 1)로 처리 — CI/커밋 전 검사용
```

> 각 단계/태스크 완료 시(자동 갱신 묶음 직후) 실행을 권장한다.
> Stop hook으로 자동 실행하려면 `.claude/settings.json`에 아래를 추가한다(선택):

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "bash scripts/check-docs.sh" }] }
    ]
  }
}
```
