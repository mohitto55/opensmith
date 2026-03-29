# Backend Patterns — {{PROJECT_NAME}} Scaffold

이 문서는 {{PROJECT_NAME}} 백엔드 코드의 패턴과 규칙을 정의합니다.
모든 백엔드 코드는 이 패턴을 따라야 합니다.

---

## 기술 스택

# Customize: Your backend tech stack
# Example:
# - C# ASP.NET Core 8.0
# - Minimal API (Controller 미사용)
# - MongoDB.Driver 2.28.0
# - JWT 인증
# Example:
# - Python FastAPI
# - SQLAlchemy + PostgreSQL
# - OAuth2 + JWT
# Example:
# - Node.js Express
# - Prisma + PostgreSQL
# - Passport.js

- {{BACKEND_FRAMEWORK}}
- {{BACKEND_ORM_OR_DRIVER}}
- {{DATABASE}}
- {{AUTH_MECHANISM}}

---

## Endpoint/Route 패턴

### 1. 라우트 구조

# Customize: Your API routing pattern
# Example (ASP.NET Minimal API):
# ```csharp
# public static class MyEndpoints {
#     public static RouteGroupBuilder MapMyEndpoints(this RouteGroupBuilder group) {
#         var myGroup = group.MapGroup("/my-resource");
#         myGroup.MapGet("/", GetAll);
#         myGroup.MapPost("/", Create);
#         return group;
#     }
# }
# ```
# Example (FastAPI):
# ```python
# router = APIRouter(prefix="/api/v1/my-resource")
# @router.get("/")
# async def get_all(): ...
# ```
# Example (Express):
# ```javascript
# const router = express.Router();
# router.get('/', getAll);
# module.exports = router;
# ```

### 2. 엔드포인트 등록

# Customize: How endpoints are registered in the app entry point
# Example: var api = app.MapGroup("/api/v1"); api.MapMyEndpoints();
# Example: app.include_router(router)
# Example: app.use('/api/v1', router)

### 3. 인증 확인

# Customize: How to check authentication in endpoints
# Example:
# ```
# var userId = context.Items["UserId"] as string;
# if (string.IsNullOrEmpty(userId)) return Unauthorized;
# ```

---

## Service 패턴

### 1. 서비스 클래스 구조

# Customize: Your service layer pattern
# Example:
# ```
# public class MyService {
#     private readonly ICollection _collection;
#     public MyService(DbService db) { _collection = db.GetCollection("name"); }
#     public async Task<Model?> FindById(string id) { ... }
# }
# ```

### 2. DI 등록

# Customize: Your dependency injection pattern
# Example: builder.Services.AddSingleton<MyService>();
# Example: app.dependency_overrides[get_db] = override_get_db

### 3. 인터페이스 사용 기준

# Customize: When to use interfaces
# Example: Only when multiple implementations exist

---

## 데이터베이스 패턴

### 1. 데이터 접근

# Customize: Your database access pattern
# Example (MongoDB):
# ```
# _collection = mongoDb.Database.GetCollection<MyModel>("collection_name");
# var filter = Builders<MyModel>.Filter.Eq(x => x.Field, value);
# ```
# Example (SQL + ORM):
# ```
# db.query(MyModel).filter(MyModel.field == value).first()
# ```

### 2. 쿼리 패턴

# Customize: Your query patterns (CRUD operations)

### 3. 인덱스 전략

# Customize: Your indexing approach

---

## Model 패턴

### 1. 데이터 모델

# Customize: Your model definition pattern
# Example (C# + MongoDB):
# ```
# [BsonIgnoreExtraElements]
# public class MyModel {
#     [BsonId] public string? MongoId { get; set; }
#     [BsonElement("name")] public string Name { get; set; }
# }
# ```
# Example (Python + SQLAlchemy):
# ```
# class MyModel(Base):
#     __tablename__ = "my_table"
#     id = Column(Integer, primary_key=True)
#     name = Column(String, nullable=False)
# ```

### 2. Request/Response DTO

# Customize: Your DTO pattern
# Example: record types, Pydantic models, Zod schemas

---

## 에러 응답 패턴

### 1. 표준 에러 형식

# Customize: Your error response format
# Example: { "error": "메시지" } with appropriate HTTP status code

### 2. HTTP 상태 코드 사용

| 상황 | 코드 |
|------|------|
| 성공 | 200 OK / 201 Created |
| 잘못된 요청 | 400 Bad Request |
| 인증 필요 | 401 Unauthorized |
| 권한 없음 | 403 Forbidden |
| 리소스 없음 | 404 Not Found |
| 요청 제한 | 429 Too Many Requests |
| 서버 에러 | 500 Internal Server Error |

### 3. 외부 서비스 에러 처리

# Customize: Your external service error handling pattern

---

## 인증 패턴

### 1. 인증 미들웨어

# Customize: Your auth middleware pattern
# Example: JWT middleware, OAuth callback handling

### 2. 엔드포인트에서 사용자 확인

# Customize: How to access the authenticated user in endpoints

### 3. 역할 기반 접근 제어

# Customize: Your RBAC pattern

---

## NEVER DO

# Customize: Your backend forbidden patterns
# Template entries below — replace with your actual rules

### 아키텍처
| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| B1 | [금지 패턴 1] | [이유] | [대안] |
| B2 | 엔드포인트에서 직접 DB 접근 금지 | 서비스 레이어 우회 | 서비스 통해서만 DB 접근 |
| B3 | 동기 DB 호출 금지 | 스레드 블로킹 | async 메서드 사용 |
| B4 | 에러 무시(empty catch) 금지 | 디버깅 불가 | 로깅 필수 |

### 보안
| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| B5 | 비밀번호/토큰 하드코딩 금지 | 보안 위험 | 환경변수/Secret Manager |
| B6 | wildcard CORS `*` 금지 | CSRF 위험 | 명시적 origin 지정 |
| B7 | MD5/SHA256 비밀번호 해싱 금지 | 무차별 대입 취약 | bcrypt/argon2 |
| B8 | dev 엔드포인트 프로덕션 노출 금지 | 무인증 접근 | 환경 가드 필수 |

### 데이터
| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| B9 | DTO와 Model 혼용 금지 | 내부 필드 노출 | 분리된 DTO 정의 |
| B10 | 검증 로직 복붙 금지 | 유지보수 어려움 | 공통 validator 추출 |

---

## 파일 구조 규칙

# Customize: Your backend directory structure
# Example:
# ```
# backend/
# ├── Program.cs (or main.py, index.js)
# ├── Endpoints/ (or routes/, routers/)
# ├── Services/ (or services/)
# ├── Models/ (or models/, schemas/)
# ├── Middleware/ (or middleware/)
# └── config
# ```

---

## 관련 문서
- [frontend-patterns.md](./frontend-patterns.md) - 프론트엔드 패턴
- [never-do.md](./never-do.md) - 통합 NEVER DO 규칙
