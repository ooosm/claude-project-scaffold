# 코딩 컨벤션 (Conventions)

> 프로젝트별 규칙이 생기면 이 파일을 재정의·확장한다. brownfield 우선.

## 공통 원칙

- 기존 코드의 스타일과 패턴을 먼저 파악하고 따른다(brownfield 우선).
- 팀 컨벤션이 없을 때만 아래 기본값을 적용한다.
- 임의로 리팩토링하거나 스타일을 변경하지 않는다.

## 기본 네이밍 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| 파일명 | kebab-case | `user-service.ts` |
| 클래스/타입 | PascalCase | `UserService` |
| 함수/변수 | camelCase | `getUserById` |
| 상수 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 폴더 | kebab-case | `user-management/` |

## 커밋 메시지

```
<type>: <짧은 요약>

[선택] 상세 설명

타입: feat, fix, refactor, test, docs, chore
```

## 주석 원칙

- **왜(Why)** 를 설명하는 주석을 쓴다(무엇은 코드가 설명).
- 당연한 내용을 반복하는 주석은 쓰지 않는다.
- 복잡한 비즈니스 로직·외부 제약·임시 조치에는 반드시 주석.

```ts
// ❌ i를 1씩 증가
i++;

// ✅ PG사 정책상 결제 금액은 최소 100원 이상이어야 함
if (amount < 100) throw new Error(...);
```

## 버전 메타데이터 (⑦ 연계)

- 모델/스키마 등 산출물에는 `version`·`since`·`lastModified` 메타데이터를 관리한다.
- DateTime은 ISO 8601, UTC. 형식·좌표 순서 등 프로젝트 고유 규약은 이 파일에 추가한다.

## 외부 의존성 버전 (⑦ 연계)

- 외부 의존성은 **호환 검증된 버전을 근거와 함께 고정**한다.
- 버전 선택·상향 시 호환성 근거를 **DEC 로그**에 남기고, README Prerequisites/Dependencies에
  검증된 버전을 표기한다(→ `decisions.md`, `readme-sync.md`).
