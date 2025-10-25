# README — API Quản Lý Nhân Viên (Tiếng Việt)

**Phiên bản:** v0.1  
**Ngày:** 2025-10-25  
**Đối tượng:** Nhà phát triển nội bộ (backend, frontend, QA, DevOps)  
**Mục đích:** README này tổng hợp các hướng dẫn thiết kế RESTful API, quy ước đặc tả API và tiêu chuẩn tài liệu cho Hệ thống Quản lý Nhân viên. Đây là nguồn chân lý duy nhất về cách thiết kế, triển khai, tài liệu hóa, kiểm thử và bảo trì API trong dự án này.

---

## 1. Tổng quan Dự án
Repository này chứa các định nghĩa API và nguyên tắc thiết kế cho Hệ thống Quản lý Nhân viên (HR Management) được xây dựng trên Oracle Database. Hệ thống quản lý dữ liệu nhân viên, phòng ban, chứng chỉ, nghỉ phép năm và giấy phép hàn. API tuân theo các quy ước RESTful và được cung cấp với hợp đồng OpenAPI. Tất cả phát triển phải tuân theo README này để tránh sự không nhất quán và nợ kỹ thuật.

**Schema Cơ sở dữ liệu:**
- **T_社員マスタ** (Employee Master) - Bảng nhân viên chính
- **T_統括部門** (Controlling Division) - Các phòng ban quản lý cấp cao
- **T_部署名** (Department Names) - Tên phòng ban liên kết với các bộ phận
- **T_資格手当** (Qualification Allowance) - Bảng master phụ cấp chứng chỉ
- **T_資格** (Qualifications) - Chứng chỉ và bằng cấp của nhân viên
- **T_年休詳細** (Annual Leave Details) - Chi tiết sử dụng nghỉ phép năm
- **T_溶接免許** (Welding License) - Chứng chỉ và giấy phép hàn

Mục tiêu chính:
- Hành vi API nhất quán và có thể dự đoán trên các dịch vụ.
- Hợp đồng rõ ràng (OpenAPI) là nguồn chân lý duy nhất.
- Bảo mật, khả năng quan sát và kiểm thử mạnh mẽ.
- Tài liệu thân thiện với nhà phát triển và ví dụ request/response.
- Tích hợp Oracle Database với hỗ trợ ký tự tiếng Nhật phù hợp.

---

## 2. Nguyên tắc & Quy ước (Tóm tắt)
- **URL dựa trên Resource:** Sử dụng danh từ (số nhiều) và đường dẫn phân cấp. Ví dụ: `/api/v1/employees`, `/api/v1/departments/{id}/employees`.
- **HTTP methods:** GET, POST, PUT, PATCH, DELETE được ánh xạ với ngữ nghĩa chuẩn.
- **JSON properties:** `camelCase` trong payloads.
- **Paths:** `kebab-case` cho các đoạn URL (ví dụ: `/annual-leaves`).
- **Ngày & giờ:** ISO-8601, UTC (ví dụ: `2024-01-15T10:30:00Z`).
- **Response envelope:** Cấu trúc chuẩn hóa cho response thành công và lỗi.
- **OpenAPI-first:** Cung cấp /api-spec/openapi.yaml (hoặc json) cho mỗi nhóm endpoint công khai.
- **Versioning:** URL versioning (`/api/v1/`) cho các thay đổi breaking.
- **Bảo mật:** OAuth2 / JWT với scopes (hr:read, hr:write, hr:admin).
- **Soft-delete mặc định**, hard delete chỉ dành cho admin hoặc các thao tác đặc biệt.
- **Contract tests:** Xác thực backend với OpenAPI trong CI (Dredd/PACT hoặc tương đương).
- **Tích hợp Oracle:** Sử dụng kiểu dữ liệu Oracle cụ thể và xử lý mã hóa ký tự tiếng Nhật (UTF-8).
- **Primary Keys:** Sử dụng Oracle sequences cho auto-increment IDs, VARCHAR2 cho string codes.

---

## 3. Response Envelope & Error Model (Bắt buộc)
Sử dụng envelope nhất quán cho tất cả response (thành công hoặc thất bại). Điều này giúp front-end code và clients phân tích response một cách đáng tin cậy.

**Success response**
```json
{
  "success": true,
  "data": { /* object or array */ },
  "message": "Thao tác hoàn thành thành công",
  "pagination": { /* optional */ }
}
```

**Error response**
```json
{
  "success": false,
  "error": "VALIDATION_ERROR",
  "code": "EMP_001",
  "message": "Thông báo thân thiện với người dùng bằng tiếng Việt cho UI",
  "details": [
    { "field": "email", "message": "Email là bắt buộc", "code": "FIELD_REQUIRED" }
  ]
}
```

- `code` là mã thân thiện với máy nội bộ (định dạng: MODULE_XXX).
- `error` là loại lỗi chung (VALIDATION_ERROR, AUTH_ERROR, RATE_LIMIT, NOT_FOUND, v.v.).
- `message` an toàn để hiển thị trên UI bằng tiếng Việt. `details` chứa thông tin validation cấp trường.

---

## 4. Pagination / Sorting / Filtering (Bắt buộc)
**Pagination**
- Query params: `page` (1-based, default=1), `size` (default=20, max=100).
- Response phải bao gồm object `pagination` với `page`, `size`, `totalElements`, `totalPages`, `hasNext`, `hasPrevious`.
- Cũng bao gồm HTTP `Link` header cho `rel="next"` và `rel="prev"` khi áp dụng.

**Sorting**
- Sử dụng param `sort` với field và direction: `sort=fullName,asc`.
- Cho phép multi-field sorting với separator `;` cho các cặp: `sort=department,asc;fullName,desc`.

**Filtering**
- Basic filters như query params: `?department=IT&isActive=true`.
- Date range: `hireDateFrom=YYYY-MM-DD&hireDateTo=YYYY-MM-DD`.
- Đối với logic tìm kiếm phức tạp sử dụng `POST /api/v1/employees/search` với JSON body (tùy chọn, và được tài liệu hóa).

---

## 5. PATCH Strategy & PUT
- Hỗ trợ **JSON Merge Patch** (`application/merge-patch+json`) cho các cập nhật một phần điển hình.
- Đối với các thao tác phức tạp trên arrays hoặc thao tác chi tiết sử dụng **JSON Patch** (`application/json-patch+json`), nhưng yêu cầu tài liệu hóa rõ ràng cho mỗi endpoint.
- `PUT` nên được sử dụng để thay thế toàn bộ biểu diễn resource; yêu cầu object đầy đủ (hoặc hành vi được định nghĩa thỏa thuận trong spec).

---

## 6. Idempotency & Concurrency
- **Idempotency-Key** header là bắt buộc cho các thao tác non-idempotent nơi việc tạo trùng lặp là không thể chấp nhận (ví dụ: `POST /employees`, `POST /employees/import`). Server phải tôn trọng key trong TTL (ví dụ: 24 giờ) và trả về cùng kết quả cho các request chia sẻ cùng key.
- **ETag** support: Tất cả GET response cho resources nên trả về `ETag` header. `PUT` & `PATCH` phải yêu cầu `If-Match` header để đảm bảo optimistic concurrency. Khi không khớp trả về `412 Precondition Failed`.

---

## 7. Delete Semantics
- **Mặc định:** Soft delete. `DELETE /api/v1/employees/{id}` đặt `deletedAt` và đánh dấu resource là đã xóa. Trả về `204 No Content`.
- **Hard delete:** Giới hạn cho admin scope. Cung cấp `DELETE /api/v1/employees/{id}?hard=true` hoặc `POST /api/v1/employees/{id}/hard-delete` (chọn một cách tiếp cận nhất quán). Tài liệu hóa nhu cầu quyền.

---

## 8. Bulk, Import, Export & Long-Running Jobs
Cung cấp endpoints cho bulk operations và background jobs:
- `POST /api/v1/employees/bulk` — chấp nhận array của employees; response `202 Accepted` với `jobId`.
- `POST /api/v1/employees/import` — upload file (multipart/form-data) cho CSV/Excel import; response `202` + `jobId`.
- `GET /api/v1/employees/export?format=csv|xlsx&filters=...` — hoặc streaming download hoặc `202` + `jobId` trả về pre-signed URL khi job hoàn thành.
- `GET /api/v1/jobs/{jobId}` — trạng thái job (pending|running|completed|failed), tiến độ, và link kết quả.

Jobs nên có thể trace (bao gồm `createdBy`, `createdAt`, `requestId`) và được lưu trữ trong thời gian retention có thể cấu hình.

---

## 9. Authentication & Authorization
- **Auth:** OAuth2 với JWT access tokens. Sử dụng authorization server bảo mật và xoay keys thường xuyên.
- **Scopes/roles:** Tối thiểu định nghĩa `hr:read`, `hr:write`, `hr:admin` và ánh xạ endpoints với scope yêu cầu.
- **Trường hợp đặc biệt:** Tài liệu hóa endpoints yêu cầu đặc quyền nâng cao (imports, exports, hard deletes).

---

## 10. Rate Limiting & Throttling
- Cung cấp rate limit headers:
  - `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` (unix timestamp).
- Khi vượt quá giới hạn trả về `429` và body:
```json
{ "success": false, "error": "RATE_LIMIT", "code": "RATE_LIMIT_EXCEEDED", "message": "Quá nhiều request. Thử lại sau.", "retryAfter": 30 }
```

---

## 11. Caching & Conditional Requests
- Hỗ trợ `Cache-Control`, `ETag`, và `Last-Modified` headers cho cacheable GET resources.
- Hỗ trợ `If-None-Match` để trả về `304 Not Modified` khi phù hợp.
- Không cache dữ liệu riêng tư cụ thể người dùng trong shared caches.

---

## 12. Observability & Auditing (Yêu cầu phi chức năng)
- Mỗi request nên propagate/request `X-Request-Id` để tương quan logs và traces.
- Cấu trúc log phải bao gồm: `requestId`, `userId` (nếu authenticated), `endpoint`, `method`, `status`, `latencyMs`.
- Audit các thay đổi quan trọng: lưu trữ `createdBy`, `updatedBy`, `createdAt`, `updatedAt`, và `changeLog` để theo dõi các sửa đổi quan trọng.
- Expose metrics cho endpoint request counts, error rates, và latency (khuyến nghị metrics thân thiện với Prometheus).

---

## 13. Documentation & OpenAPI Contract (BẮT BUỘC)
- Duy trì OpenAPI 3.1 document trong `api-spec/openapi.yaml` (hoặc json). OpenAPI là hợp đồng được sử dụng cho:
  - Client SDK generation
  - Mock server cho frontend
  - Contract testing (CI)
  - Swagger UI cho tham khảo nhanh
- Bao gồm `components.schemas` cho tất cả major resources (Employee, Department, Qualification, AnnualLeave, Job).
- Bao gồm examples cho success và error responses cho mỗi endpoint.
- Giữ `api-spec` đồng bộ với implementation — CI phải chạy OpenAPI validation step.

---

## 14. Testing & CI
- Thêm contract tests (Dredd hoặc PACT) xác thực runtime API với OpenAPI spec.
- Thêm unit tests cho serialization/validation logic và integration tests cho các flow quan trọng (search, import, export, concurrency).
- CI pipeline nên chạy: lint -> unit tests -> contract tests -> security scan -> deploy (staging).

---

## 15. Documentation Standards (Cách viết API spec và docs)
Sử dụng cấu trúc tối thiểu sau cho bất kỳ spec file và service README:

**File metadata header (đầu mỗi spec file)**
```
# Service / API Title
version: v1.0
date: 2025-10-25
owner: <team or person>
status: draft | review | approved
```

**Directory layout (khuyến nghị)**
```
/api-spec/
  openapi.yaml
  employees/
    employees.yaml
    employees_examples.json
/docs/
  README.vi.md
  RESTful_API_Guidelines_v1.1.md
CHANGELOG.md
CONTRIBUTORS.md
```
**Quy tắc viết tài liệu**
- Sử dụng present tense, imperative mood khi phù hợp (ví dụ: "Trả về 204 khi..."). Ngắn gọn.
- Cung cấp examples cho request và response cho mỗi endpoint.
- Luôn tài liệu hóa permissions và scopes yêu cầu cho mỗi endpoint.
- Sử dụng tables cho danh sách parameters và status codes.
- Cung cấp ví dụ "Usage" ngắn và section "Common Errors" cho mỗi endpoint.

---

## 16. API Naming & Property Conventions
- Path segments: `kebab-case` (ví dụ: `/annual-leaves`)
- JSON keys: `camelCase` (ví dụ: `employeeCode`)
- Boolean query params: `isActive=true` không phải `active=1`.
- Sử dụng `id` hoặc `uuid` nhất quán cho primary keys. Tài liệu hóa định dạng được sử dụng (integer vs uuid).

---

## 17. Example Resource Schema (copy vào OpenAPI components)
```yaml
Employee:
  type: object
  properties:
    employeeCode:
      type: string
      maxLength: 50
      description: "Primary key từ T_社員マスタ"
    fullName:
      type: string
      description: "氏名 từ T_社員マスタ"
    kanaName:
      type: string
      nullable: true
      description: "かな氏名 từ T_社員マスタ"
    divisionName:
      type: string
      description: "部門名 từ T_社員マスタ"
    departmentName:
      type: string
      description: "部署名 từ T_社員マスタ"
    gender:
      type: string
      description: "性別 từ T_社員マスタ"
    dateOfBirth:
      type: string
      format: date
      description: "生年月日 từ T_社員マスタ"
    hireDate:
      type: string
      format: date
      description: "入社年月日 từ T_社員マスタ"
    resignationDate:
      type: string
      format: date
      nullable: true
      description: "退職年月日 từ T_社員マスタ"
    currentAddress:
      type: string
      nullable: true
      description: "住所1 từ T_社員マスタ"
    familyAddress:
      type: string
      nullable: true
      description: "住所2 từ T_社員マスタ"
    mobilePhone:
      type: string
      nullable: true
      description: "TEL携帯用 từ T_社員マスタ"
    weddingAnniversary:
      type: string
      format: date
      nullable: true
      description: "結婚記念日 từ T_社員マスタ"
    totalAnnualLeave:
      type: number
      format: float
      description: "年休合計 từ T_社員マスタ"
    usedAnnualLeave:
      type: number
      format: float
      description: "取得日数 từ T_社員マスタ"
    remainingAnnualLeave:
      type: number
      format: float
      description: "残日数 từ T_社員マスタ"
    isRetired:
      type: boolean
      default: false
      description: "Tính toán từ 退職年月日"
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
      description: "部門ID từ T_統括部門"
    divisionName:
      type: string
      description: "統括部門 từ T_統括部門"
    departmentId:
      type: string
      description: "部署ID từ T_部署名"
    departmentName:
      type: string
      description: "部署名 từ T_部署名"

Qualification:
  type: object
  properties:
    id:
      type: integer
      description: "ID từ T_資格"
    employeeCode:
      type: string
      description: "社員コード từ T_資格"
    qualificationName:
      type: string
      description: "名称 từ T_資格"
    grade:
      type: string
      description: "等級 từ T_資格"
    type:
      type: string
      description: "種類 từ T_資格"
    allowanceAmount:
      type: number
      format: float
      description: "金額 từ T_資格"
    certificateNumber:
      type: string
      nullable: true
      description: "番号 từ T_資格"
    acquisitionDate:
      type: string
      format: date
      nullable: true
      description: "取得日 từ T_資格"
    isChecked:
      type: boolean
      description: "チェック từ T_資格"
```

---

## 18. Checklist Trước Khi Merge API Change
- [ ] OpenAPI spec được cập nhật và commit vào `api-spec/`.
- [ ] Example requests/responses được bao gồm trong spec.
- [ ] New fields được thêm vào `components.schemas` với descriptions.
- [ ] Security scopes và permissions được tài liệu hóa.
- [ ] Contract tests được thêm hoặc cập nhật.
- [ ] Migration strategy cho breaking changes được tài liệu hóa (deprecation timeline).
- [ ] Changelog entry được tạo (CHANGELOG.md).
- [ ] QA checklist passed (manual test cases hoặc automated integration tests).
- [ ] Oracle database schema changes được tài liệu hóa và migration scripts được cung cấp.
- [ ] Japanese character encoding (UTF-8) handling được xác minh.
- [ ] Oracle sequence và trigger updates được kiểm thử.

---

## 19. Database Schema Reference
**Oracle Tables và Relationships:**
- **T_社員マスタ** (Employee Master) - Bảng dữ liệu nhân viên chính
- **T_統括部門** (Controlling Division) - Các phòng ban quản lý cấp cao
- **T_部署名** (Department Names) - Tên phòng ban liên kết với divisions qua 部門ID
- **T_資格手当** (Qualification Allowance) - Bảng master cho qualification allowances
- **T_資格** (Qualifications) - Employee qualifications liên kết với T_社員マスタ và T_資格手当
- **T_年休詳細** (Annual Leave Details) - Annual leave usage details liên kết với T_社員マスタ
- **T_溶接免許** (Welding License) - Welding certificates và licenses

**Key Relationships:**
- T_部署名.部門ID → T_統括部門.部門ID
- T_資格.社員コード → T_社員マスタ.社員コード
- T_資格.資格ID → T_資格手当.資格ID
- T_年休詳細.社員コード → T_社員マスタ.社員コード

**Oracle Sequences:**
- SEQ_統括部門_ID, SEQ_資格手当_ID, SEQ_資格_ID, SEQ_年休詳細_ID, SEQ_溶接免許_ID

---

## 20. Contributors / Contacts
- API owner / contact: Chính (hoặc assigned team lead)
- Security owner: infra/security team
- QA contact: QA lead
- Database owner: Oracle DBA team
- Đối với câu hỏi nhanh, mở issue trong repository hoặc message owner trên internal chat.

---

## 21. Ghi chú Cuối cùng (Nghiêm ngặt, nhất quán)
README này là prescriptive: hãy tuân theo. API không nhất quán tạo ra ma sát cho frontend, automation, SDKs và tạo ra nợ kỹ thuật. Nếu có gì trong tài liệu này không rõ ràng hoặc thiếu, hãy thêm đề xuất cụ thể, cập nhật OpenAPI skeleton và mở PR — không triển khai thay đổi ad-hoc mà không cập nhật spec trước.

**Oracle Database Considerations:**
- Luôn sử dụng Oracle data types phù hợp (VARCHAR2, NUMBER, DATE)
- Xử lý Japanese character encoding đúng cách (UTF-8)
- Sử dụng Oracle sequences cho auto-increment fields
- Kiểm thử với Oracle-specific features (triggers, constraints, indexes)
- Cân nhắc Oracle performance optimization (indexes, query plans)

---
