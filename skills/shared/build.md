# 서브스킬: 빌드 검증

## 실행

```bash
# 백엔드
cd backend/ && {{BACKEND_BUILD_CMD}}

# 프론트엔드
cd frontend/ && {{FRONTEND_BUILD_CMD}}
```

### 분기

```
성공 → state.json: current_step++

실패 → 에러 분석 → 코드 수정 → 재빌드
  ├─ 재시도 1회 → 수정 후 재빌드
  ├─ 재시도 2회 → 수정 후 재빌드
  └─ 재시도 3회 → 중단, 원인 분석 보고
```

- `state.json`에 `build_retry_count` 기록
- 3회 연속 실패 시 사용자에게 보고 후 파이프라인 중단
