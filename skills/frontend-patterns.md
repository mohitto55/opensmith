# Frontend Patterns — {{PROJECT_NAME}} Scaffold

이 문서는 {{PROJECT_NAME}} 프론트엔드 코드의 패턴과 규칙을 정의합니다.
모든 프론트엔드 코드는 이 패턴을 따라야 합니다.

---

## 기술 스택

# Customize: Your frontend tech stack
# Example:
# - Next.js 14 App Router (TypeScript)
# - React Server Components + Client Components
# - Pure CSS (globals.css) — Tailwind 미사용
# - Google OAuth (@react-oauth/google)
# - lucide-react (아이콘)

- {{FRONTEND_FRAMEWORK}}
- {{FRONTEND_STYLING}}
- {{FRONTEND_AUTH}}
- {{FRONTEND_ICONS}}

---

## 컴포넌트 패턴

### 1. export 스타일

# Customize: Your component export convention
# Example (React/Next.js):
# ```tsx
# 'use client';
# export default function MyComponent({ title }: MyComponentProps) {
#   return <div>{title}</div>;
# }
# ```
# Example (Vue):
# ```vue
# <script setup lang="ts">
# defineProps<{ title: string }>()
# </script>
# ```

### 2. Server/Client 분리 (해당 시)

# Customize: Your server/client component separation rules
# Example (Next.js App Router):
# - page.tsx = Server Component (데이터 fetch)
# - *Client.tsx = Client Component (인터랙션)
# Example (Nuxt):
# - pages/ = auto-routed pages
# - components/ = reusable components

### 3. Props/Types 패턴

# Customize: Your type definition convention
# Example:
# ```tsx
# interface MyComponentProps {
#   title: string;
#   onClick: () => void;
# }
# ```

### 4. 프레임워크별 규칙

# Customize: Framework-specific rules
# Example (Next.js): 'use client' rules, RSC constraints
# Example (Vue): Composition API vs Options API

---

## API 호출 패턴

### 1. 인증된 요청

# Customize: Your auth fetch pattern
# Example:
# ```tsx
# import { authFetch } from '../lib/auth';
# const res = await authFetch(`${API_URL}/api/v1/endpoint`, { ... });
# ```

### 2. API Base URL

# Customize: Your API URL configuration
# Example:
# ```tsx
# const API_URL = process.env.NEXT_PUBLIC_API_URL || '';
# ```

### 3. 비동기 패턴

# Customize: Your async pattern convention
# Example: Always use async/await (no .then() chains)

---

## 스타일링 패턴

### 1. 스타일링 방식

# Customize: Your styling approach
# Example: Pure CSS classes in globals.css
# Example: Tailwind CSS utility classes
# Example: CSS Modules
# Example: styled-components

### 2. 디자인 토큰 / CSS 변수

# Customize: Your design tokens
# Example:
# ```css
# :root {
#   --bg-primary: #1a1a1a;
#   --text-primary: #ffffff;
#   --accent: #7c5cff;
#   --border: #3a3a3a;
#   --radius: 12px;
# }
# ```

### 3. 동적 스타일

# Customize: When to use inline styles vs classes
# Example: Inline styles only for data-driven dynamic values

### 4. 클래스 네이밍

# Customize: Your CSS naming convention
# Example: BEM-like (.card, .card-body, .card-title)
# Example: Utility-first (Tailwind)

---

## 상태 관리

### 1. 전역 상태

# Customize: Your global state approach
# Example: AuthContext (React Context)
# Example: Pinia (Vue)
# Example: Redux/Zustand

### 2. 로컬 상태

# Customize: Your local state conventions
# Example: useState, limit per component, custom hook extraction rules

### 3. 메모이제이션 규칙

# Customize: Your memoization conventions
# Example: useCallback for functions in useEffect deps or passed to children

---

## NEVER DO

# Customize: Your frontend forbidden patterns
# Template entries below — replace with your actual rules

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| F1 | [금지 패턴 1] | [이유] | [대안] |
| F2 | [금지 패턴 2] | [이유] | [대안] |
| F3 | [금지 패턴 3] | [이유] | [대안] |
| F4 | `any` 타입 사용 금지 | 타입 안전성 파괴 | 구체적 타입 정의 |
| F5 | API URL 하드코딩 금지 | 환경별 차이 | 환경변수 사용 |
| F6 | API 에러 무시(empty catch) 금지 | 디버깅 불가 | 최소 로깅 |
| F7 | 단일 컴포넌트 500줄 초과 금지 | 유지보수 어려움 | 분리 |

---

## 파일 구조 규칙

# Customize: Your frontend directory structure
# Example:
# ```
# frontend/
# ├── app/                    (or src/, pages/)
# │   ├── page.tsx            (or index.tsx)
# │   ├── layout.tsx
# │   ├── globals.css
# │   ├── lib/
# │   ├── components/
# │   └── [feature]/
# └── package.json
# ```

---

## 관련 문서
- [backend-patterns.md](./backend-patterns.md) - 백엔드 패턴
- [never-do.md](./never-do.md) - 통합 NEVER DO 규칙
