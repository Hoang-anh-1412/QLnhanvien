# README — Employee Management API (English)

**Version:** v0.1
**Date:** 2025-10-25
**Audience:** Internal developers (backend, frontend, QA, DevOps)
**Purpose:** This README consolidates RESTful API design guidelines, API specification conventions, and documentation standards for the Employee Management System. It is a single source of truth for how to design, implement, document, test, and maintain APIs in this project.

---

## 1. Project Overview
This repository contains API definitions and design principles for the Employee Management System (HR Management) built on Oracle Database. The system manages employee data, departments, qualifications, annual leave, and welding licenses. APIs follow RESTful conventions and are delivered with an OpenAPI contract. All development must align with this README to prevent inconsistency and technical debt.

**Database Schema:**
- **T_社員マスタ** (Employee Master) - Main employee table
- **T_統括部門** (Controlling Division) - High-level management departments
- **T_部署名** (Department Names) - Department names linked to divisions
- **T_資格手当** (Qualification Allowance) - Qualification allowance master
- **T_資格** (Qualifications) - Employee qualifications and certificates
- **T_年休詳細** (Annual Leave Details) - Annual leave usage details
- **T_溶接免許** (Welding License) - Welding certificates and licenses

Key goals:
- Predictable, consistent API behavior across services.
- Clear contract (OpenAPI) as the single source of truth.
- Strong security, observability, and testability.
- Developer-friendly docs and example requests/responses.
- Oracle Database integration with proper Japanese character support.

---

## 2. Principles & Conventions (Summary)
- **Resource-based URLs:** Use nouns (plural) and hierarchical paths. Example: `/api/v1/employees`, `/api/v1/departments/{id}/employees`.
- **HTTP methods:** GET, POST, PUT, PATCH, DELETE mapped to standard semantics.
- **JSON properties:** `camelCase` in payloads.
- **Paths:** `kebab-case` for URL segments (e.g. `/annual-leaves`).
- **Dates & times:** ISO-8601, UTC (e.g. `2024-01-15T10:30:00Z`).
- **Response envelope:** Standardized structure for success and error responses.
- **OpenAPI-first:** Provide /api-spec/openapi.yaml (or json) for every public endpoint group.
- **Versioning:** URL versioning (`/api/v1/`) for breaking changes.
- **Security:** OAuth2 / JWT with scopes (hr:read, hr:write, hr:admin).
- **Soft-delete by default**, hard delete only for admin or special operations.
- **Contract tests:** Validate backend against OpenAPI in CI (Dredd/PACT or equivalent).
- **Oracle Integration:** Use Oracle-specific data types and handle Japanese character encoding (UTF-8).
- **Primary Keys:** Use Oracle sequences for auto-increment IDs, VARCHAR2 for string codes.

---

## 3. Response Envelope & Error Model (Required)
Use a consistent envelope for all responses (successful or failed). This helps front-end code and clients to parse responses reliably.

**Success response**
```json
{
  "success": true,
  "data": { /* object or array */ },
  "message": "Operation completed successfully",
  "pagination": { /* optional */ }
}
```

**Error response**
```json
{
  "success": false,
  "error": "VALIDATION_ERROR",
  "code": "EMP_001",
  "message": "User-friendly message in Vietnamese for UI",
  "details": [
    { "field": "email", "message": "Email is required", "code": "FIELD_REQUIRED" }
  ]
}
```

- `code` is an internal machine-friendly code (format: MODULE_XXX).
- `error` is a general error type (VALIDATION_ERROR, AUTH_ERROR, RATE_LIMIT, NOT_FOUND, etc.).
- `message` is safe to show on UI in Vietnamese. `details` contains field-level validation information.

---

## 4. Pagination / Sorting / Filtering (Required)
**Pagination**
- Query params: `page` (1-based, default=1), `size` (default=20, max=100).
- Response must include `pagination` object with `page`, `size`, `totalElements`, `totalPages`, `hasNext`, `hasPrevious`.
- Also include HTTP `Link` header for `rel="next"` and `rel="prev"` when applicable.

**Sorting**
- Use `sort` param with field and direction: `sort=fullName,asc`.
- Allow multi-field sorting with `;` separator for pairs: `sort=department,asc;fullName,desc`.

**Filtering**
- Basic filters as query params: `?department=IT&isActive=true`.
- Date range: `hireDateFrom=YYYY-MM-DD&hireDateTo=YYYY-MM-DD`.
- For complex search logic use `POST /api/v1/employees/search` with JSON body (optional, and documented).

---

## 5. PATCH Strategy & PUT
- Support **JSON Merge Patch** (`application/merge-patch+json`) for typical partial updates.
- For complex operations on arrays or fine-grained operations use **JSON Patch** (`application/json-patch+json`), but require explicit documentation per endpoint.
- `PUT` should be used to replace a full resource representation; require full object (or defined behavior agreed in spec).

---

## 6. Idempotency & Concurrency
- **Idempotency-Key** header is required for non-idempotent operations where duplicate creation is unacceptable (e.g. `POST /employees`, `POST /employees/import`). The server must honor the key for a TTL (e.g., 24 hours) and return the same result for requests that share the same key.
- **ETag** support: All GET responses for resources should return an `ETag` header. `PUT` & `PATCH` must require `If-Match` header to ensure optimistic concurrency. On mismatch return `412 Precondition Failed`.

---

## 7. Delete Semantics
- **Default:** Soft delete. `DELETE /api/v1/employees/{id}` sets `deletedAt` and marks resource as deleted. Return `204 No Content`.
- **Hard delete:** Restricted to admin scope. Provide `DELETE /api/v1/employees/{id}?hard=true` or `POST /api/v1/employees/{id}/hard-delete` (choose one consistent approach). Document permission needs.

---

## 8. Bulk, Import, Export & Long-Running Jobs
Provide endpoints for bulk operations and background jobs:
- `POST /api/v1/employees/bulk` — accepts array of employees; response `202 Accepted` with `jobId`.
- `POST /api/v1/employees/import` — upload file (multipart/form-data) for CSV/Excel import; response `202` + `jobId`.
- `GET /api/v1/employees/export?format=csv|xlsx&filters=...` — either streaming download or `202` + `jobId` returning a pre-signed URL when job completes.
- `GET /api/v1/jobs/{jobId}` — job status (pending|running|completed|failed), progress, and result link.

Jobs should be traceable (include `createdBy`, `createdAt`, `requestId`) and stored for a configurable retention period.

---

## 9. Authentication & Authorization
- **Auth:** OAuth2 with JWT access tokens. Use a secure authorization server and rotate keys regularly.
- **Scopes/roles:** At minimum define `hr:read`, `hr:write`, `hr:admin` and map endpoints to required scope.
- **Special cases:** Document endpoints requiring elevated privileges (imports, exports, hard deletes).

---

## 10. Rate Limiting & Throttling
- Provide rate limit headers:
  - `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` (unix timestamp).
- When limit exceeded return `429` and body:
```json
{ "success": false, "error": "RATE_LIMIT", "code": "RATE_LIMIT_EXCEEDED", "message": "Too many requests. Try again later.", "retryAfter": 30 }
```

---

## 11. Caching & Conditional Requests
- Support `Cache-Control`, `ETag`, and `Last-Modified` headers for cacheable GET resources.
- Support `If-None-Match` to return `304 Not Modified` when appropriate.
- Do not cache user-specific private data in shared caches.

---

## 12. Observability & Auditing (Non-functional requirements)
- Every request should propagate/request `X-Request-Id` to correlate logs and traces.
- Log structure must include: `requestId`, `userId` (if authenticated), `endpoint`, `method`, `status`, `latencyMs`.
- Audit critical changes: store `createdBy`, `updatedBy`, `createdAt`, `updatedAt`, and a `changeLog` to track important modifications.
- Expose metrics for endpoint request counts, error rates, and latency (Prometheus-friendly metrics recommended).

---

## 13. Documentation & OpenAPI Contract (MANDATORY)
- Maintain an OpenAPI 3.1 document in `api-spec/openapi.yaml` (or json). OpenAPI is the contract used for:
  - Client SDK generation
  - Mock server for frontend
  - Contract testing (CI)
  - Swagger UI for quick reference
- Include `components.schemas` for all major resources (Employee, Department, Qualification, AnnualLeave, Job).
- Include examples for success and error responses for each endpoint.
- Keep `api-spec` synchronized with implementation — CI must run an OpenAPI validation step.

---

## 14. Testing & CI
- Add contract tests (Dredd or PACT) that validate the runtime API against OpenAPI spec.
- Add unit tests for serialization/validation logic and integration tests for important flows (search, import, export, concurrency).
- CI pipeline should run: lint -> unit tests -> contract tests -> security scan -> deploy (staging).

---

## 15. Documentation Standards (How to write API spec and docs)
Use the following minimal structure for any spec file and service README:

**File metadata header (top of every spec file)**
```
# Service / API Title
version: v1.0
date: 2025-10-25
owner: <team or person>
status: draft | review | approved
```

**Directory layout (recommended)**
```
/api-spec/
  openapi.yaml
  employees/
    employees.yaml
    employees_examples.json
/docs/
  README.en.md
  RESTful_API_Guidelines_v1.1.md
CHANGELOG.md
CONTRIBUTORS.md
```
**Documentation writing rules**
- Use present tense, imperative mood where appropriate (e.g., “Return 204 when...”). Be concise.
- Provide examples for request and response for each endpoint.
- Always document required permissions and scopes per endpoint.
- Use tables for lists of parameters and status codes.
- Provide a short "Usage" example and a "Common Errors" section for each endpoint.

---

## 16. API Naming & Property Conventions
- Path segments: `kebab-case` (e.g., `/annual-leaves`)
- JSON keys: `camelCase` (e.g., `employeeCode`)
- Boolean query params: `isActive=true` not `active=1`.
- Use `id` or `uuid` consistently for primary keys. Document the format used (integer vs uuid).

---

## 17. Example Resource Schema (copy into OpenAPI components)
```yaml
Employee:
  type: object
  properties:
    employeeCode:
      type: string
      maxLength: 50
      description: "Primary key from T_社員マスタ"
    fullName:
      type: string
      description: "氏名 from T_社員マスタ"
    kanaName:
      type: string
      nullable: true
      description: "かな氏名 from T_社員マスタ"
    divisionName:
      type: string
      description: "部門名 from T_社員マスタ"
    departmentName:
      type: string
      description: "部署名 from T_社員マスタ"
    gender:
      type: string
      description: "性別 from T_社員マスタ"
    dateOfBirth:
      type: string
      format: date
      description: "生年月日 from T_社員マスタ"
    hireDate:
      type: string
      format: date
      description: "入社年月日 from T_社員マスタ"
    resignationDate:
      type: string
      format: date
      nullable: true
      description: "退職年月日 from T_社員マスタ"
    currentAddress:
      type: string
      nullable: true
      description: "住所1 from T_社員マスタ"
    familyAddress:
      type: string
      nullable: true
      description: "住所2 from T_社員マスタ"
    mobilePhone:
      type: string
      nullable: true
      description: "TEL携帯用 from T_社員マスタ"
    weddingAnniversary:
      type: string
      format: date
      nullable: true
      description: "結婚記念日 from T_社員マスタ"
    totalAnnualLeave:
      type: number
      format: float
      description: "年休合計 from T_社員マスタ"
    usedAnnualLeave:
      type: number
      format: float
      description: "取得日数 from T_社員マスタ"
    remainingAnnualLeave:
      type: number
      format: float
      description: "残日数 from T_社員マスタ"
    isRetired:
      type: boolean
      default: false
      description: "Computed from 退職年月日"
    createdAt:
      type: string
      format: date-time
    updatedAt:
      type: string
      format: date-time
  required:
    - employeeCode
    - fullName
    - dateOfBirth
    - hireDate

Department:
  type: object
  properties:
    divisionId:
      type: integer
      description: "部門ID from T_統括部門"
    divisionName:
      type: string
      description: "統括部門 from T_統括部門"
    departmentId:
      type: string
      description: "部署ID from T_部署名"
    departmentName:
      type: string
      description: "部署名 from T_部署名"

Qualification:
  type: object
  properties:
    id:
      type: integer
      description: "ID from T_資格"
    employeeCode:
      type: string
      description: "社員コード from T_資格"
    qualificationName:
      type: string
      description: "名称 from T_資格"
    grade:
      type: string
      description: "等級 from T_資格"
    type:
      type: string
      description: "種類 from T_資格"
    allowanceAmount:
      type: number
      format: float
      description: "金額 from T_資格"
    certificateNumber:
      type: string
      nullable: true
      description: "番号 from T_資格"
    acquisitionDate:
      type: string
      format: date
      nullable: true
      description: "取得日 from T_資格"
    isChecked:
      type: boolean
      description: "チェック from T_資格"
```

---

## 18. Checklist Before Merging an API Change
- [ ] OpenAPI spec updated and committed to `api-spec/`.
- [ ] Example requests/responses included in spec.
- [ ] New fields added to `components.schemas` with descriptions.
- [ ] Security scopes and permissions documented.
- [ ] Contract tests added or updated.
- [ ] Migration strategy for breaking changes documented (deprecation timeline).
- [ ] Changelog entry created (CHANGELOG.md).
- [ ] QA checklist passed (manual test cases or automated integration tests).
- [ ] Oracle database schema changes documented and migration scripts provided.
- [ ] Japanese character encoding (UTF-8) handling verified.
- [ ] Oracle sequence and trigger updates tested.

---

## 19. Database Schema Reference
**Oracle Tables and Relationships:**
- **T_社員マスタ** (Employee Master) - Primary employee data table
- **T_統括部門** (Controlling Division) - High-level management departments
- **T_部署名** (Department Names) - Department names linked to divisions via 部門ID
- **T_資格手当** (Qualification Allowance) - Master table for qualification allowances
- **T_資格** (Qualifications) - Employee qualifications linked to T_社員マスタ and T_資格手当
- **T_年休詳細** (Annual Leave Details) - Annual leave usage details linked to T_社員マスタ
- **T_溶接免許** (Welding License) - Welding certificates and licenses

**Key Relationships:**
- T_部署名.部門ID → T_統括部門.部門ID
- T_資格.社員コード → T_社員マスタ.社員コード
- T_資格.資格ID → T_資格手当.資格ID
- T_年休詳細.社員コード → T_社員マスタ.社員コード

**Oracle Sequences:**
- SEQ_統括部門_ID, SEQ_資格手当_ID, SEQ_資格_ID, SEQ_年休詳細_ID, SEQ_溶接免許_ID

---

## 20. Contributors / Contacts
- API owner / contact: Chính (or assigned team lead)
- Security owner: infra/security team
- QA contact: QA lead
- Database owner: Oracle DBA team
- For quick questions, open an issue in the repository or message the owner on internal chat.

---

## 21. Final Notes (Be strict, be consistent)
This README is prescriptive: follow it. Inconsistent APIs create friction for frontend, automation, SDKs and produce technical debt. If something in this document is unclear or missing, add a concrete proposal, update the OpenAPI skeleton and open a PR — do not implement ad-hoc changes without updating the spec first.

**Oracle Database Considerations:**
- Always use proper Oracle data types (VARCHAR2, NUMBER, DATE)
- Handle Japanese character encoding correctly (UTF-8)
- Use Oracle sequences for auto-increment fields
- Test with Oracle-specific features (triggers, constraints, indexes)
- Consider Oracle performance optimization (indexes, query plans)

---
