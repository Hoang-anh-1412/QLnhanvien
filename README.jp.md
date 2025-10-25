# README — 社員管理API (日本語)

**バージョン:** v0.1  
**日付:** 2025-10-25  
**対象者:** 内部開発者 (backend, frontend, QA, DevOps)  
**目的:** このREADMEは、社員管理システムのRESTful API設計ガイドライン、API仕様規約、および文書化標準を統合したものです。このプロジェクトでAPIを設計、実装、文書化、テスト、保守する方法の単一の真実の源です。

---

## 1. プロジェクト概要
このリポジトリには、Oracle Database上に構築された社員管理システム（HR Management）のAPI定義と設計原則が含まれています。システムは社員データ、部署、資格、年次休暇、溶接免許を管理します。APIはRESTful規約に従い、OpenAPI契約で提供されます。すべての開発は、不整合と技術的負債を防ぐためにこのREADMEに従う必要があります。

**データベーススキーマ:**
- **T_社員マスタ** (Employee Master) - メインの社員テーブル
- **T_統括部門** (Controlling Division) - 高レベル管理部門
- **T_部署名** (Department Names) - 部門にリンクされた部署名
- **T_資格手当** (Qualification Allowance) - 資格手当マスタ
- **T_資格** (Qualifications) - 社員の資格と証明書
- **T_年休詳細** (Annual Leave Details) - 年次休暇使用詳細
- **T_溶接免許** (Welding License) - 溶接証明書と免許

主要目標:
- サービス間での予測可能で一貫したAPI動作。
- 単一の真実の源としての明確な契約（OpenAPI）。
- 強力なセキュリティ、可観測性、テスト可能性。
- 開発者フレンドリーなドキュメントとリクエスト/レスポンスの例。
- 適切な日本語文字サポートを備えたOracle Database統合。

---

## 2. 原則と規約（概要）
- **リソースベースURL:** 名詞（複数形）と階層パスを使用。例: `/api/v1/employees`, `/api/v1/departments/{id}/employees`。
- **HTTPメソッド:** 標準セマンティクスにマッピングされたGET、POST、PUT、PATCH、DELETE。
- **JSONプロパティ:** ペイロードで`camelCase`。
- **パス:** URLセグメントで`kebab-case`（例: `/annual-leaves`）。
- **日付と時刻:** ISO-8601、UTC（例: `2024-01-15T10:30:00Z`）。
- **レスポンスエンベロープ:** 成功とエラーレスポンスの標準化された構造。
- **OpenAPI-first:** すべてのパブリックエンドポイントグループに/api-spec/openapi.yaml（またはjson）を提供。
- **バージョニング:** 破壊的変更のためのURLバージョニング（`/api/v1/`）。
- **セキュリティ:** スコープ（hr:read、hr:write、hr:admin）を持つOAuth2 / JWT。
- **デフォルトでソフト削除**、ハード削除は管理者または特別な操作のみ。
- **契約テスト:** CIでOpenAPIに対してバックエンドを検証（Dredd/PACTまたは同等）。
- **Oracle統合:** Oracle固有のデータ型を使用し、日本語文字エンコーディング（UTF-8）を処理。
- **主キー:** オートインクリメントIDにOracleシーケンス、文字列コードにVARCHAR2を使用。

---

## 3. レスポンスエンベロープとエラーモデル（必須）
すべてのレスポンス（成功または失敗）に一貫したエンベロープを使用します。これにより、フロントエンドコードとクライアントがレスポンスを確実に解析できます。

**成功レスポンス**
```json
{
  "success": true,
  "data": { /* object or array */ },
  "message": "操作が正常に完了しました",
  "pagination": { /* optional */ }
}
```

**エラーレスポンス**
```json
{
  "success": false,
  "error": "VALIDATION_ERROR",
  "code": "EMP_001",
  "message": "UI用のユーザーフレンドリーなメッセージ（ベトナム語）",
  "details": [
    { "field": "email", "message": "メールアドレスは必須です", "code": "FIELD_REQUIRED" }
  ]
}
```

- `code`は内部のマシンフレンドリーなコード（形式: MODULE_XXX）。
- `error`は一般的なエラータイプ（VALIDATION_ERROR、AUTH_ERROR、RATE_LIMIT、NOT_FOUNDなど）。
- `message`はUIで安全に表示できます（ベトナム語）。`details`にはフィールドレベルの検証情報が含まれます。

---

## 4. ページネーション / ソート / フィルタリング（必須）
**ページネーション**
- クエリパラメータ: `page`（1ベース、デフォルト=1）、`size`（デフォルト=20、最大=100）。
- レスポンスには`page`、`size`、`totalElements`、`totalPages`、`hasNext`、`hasPrevious`を含む`pagination`オブジェクトを含める必要があります。
- 該当する場合は`rel="next"`と`rel="prev"`のHTTP `Link`ヘッダーも含めます。

**ソート**
- フィールドと方向で`sort`パラメータを使用: `sort=fullName,asc`。
- ペアの`;`セパレータでマルチフィールドソートを許可: `sort=department,asc;fullName,desc`。

**フィルタリング**
- クエリパラメータとしての基本フィルター: `?department=IT&isActive=true`。
- 日付範囲: `hireDateFrom=YYYY-MM-DD&hireDateTo=YYYY-MM-DD`。
- 複雑な検索ロジックには`POST /api/v1/employees/search`をJSONボディで使用（オプション、文書化）。

---

## 5. PATCH戦略とPUT
- 典型的な部分更新に**JSON Merge Patch**（`application/merge-patch+json`）をサポート。
- 配列の複雑な操作や細かい操作には**JSON Patch**（`application/json-patch+json`）を使用しますが、エンドポイントごとに明示的な文書化が必要です。
- `PUT`は完全なリソース表現を置き換えるために使用すべきです。完全なオブジェクト（または仕様で合意された定義された動作）が必要です。

---

## 6. べき等性とコンカレンシー
- **Idempotency-Key**ヘッダーは、重複作成が受け入れられない非べき等操作（例: `POST /employees`、`POST /employees/import`）に必要です。サーバーはTTL（例: 24時間）の間キーを尊重し、同じキーを共有するリクエストに対して同じ結果を返す必要があります。
- **ETag**サポート: リソースのすべてのGETレスポンスは`ETag`ヘッダーを返すべきです。`PUT`と`PATCH`は楽観的コンカレンシーを確保するために`If-Match`ヘッダーを要求する必要があります。不一致の場合は`412 Precondition Failed`を返します。

---

## 7. 削除セマンティクス
- **デフォルト:** ソフト削除。`DELETE /api/v1/employees/{id}`は`deletedAt`を設定し、リソースを削除済みとしてマークします。`204 No Content`を返します。
- **ハード削除:** 管理者スコープに制限。`DELETE /api/v1/employees/{id}?hard=true`または`POST /api/v1/employees/{id}/hard-delete`を提供（一貫したアプローチを選択）。権限要件を文書化。

---

## 8. バルク、インポート、エクスポート、長時間実行ジョブ
バルク操作とバックグラウンドジョブのエンドポイントを提供:
- `POST /api/v1/employees/bulk` — 社員の配列を受け入れます。`jobId`で`202 Accepted`レスポンス。
- `POST /api/v1/employees/import` — CSV/Excelインポート用ファイルアップロード（multipart/form-data）。`202` + `jobId`レスポンス。
- `GET /api/v1/employees/export?format=csv|xlsx&filters=...` — ストリーミングダウンロードまたは`202` + `jobId`でジョブ完了時にプリサインドURLを返します。
- `GET /api/v1/jobs/{jobId}` — ジョブステータス（pending|running|completed|failed）、進捗、結果リンク。

ジョブは追跡可能（`createdBy`、`createdAt`、`requestId`を含む）で、設定可能な保持期間で保存されるべきです。

---

## 9. 認証と認可
- **認証:** JWTアクセストークンを使用したOAuth2。セキュアな認証サーバーを使用し、キーを定期的にローテーション。
- **スコープ/ロール:** 最低限`hr:read`、`hr:write`、`hr:admin`を定義し、エンドポイントを必要なスコープにマッピング。
- **特別なケース:** 昇格された権限を必要とするエンドポイント（インポート、エクスポート、ハード削除）を文書化。

---

## 10. レート制限とスロットリング
- レート制限ヘッダーを提供:
  - `X-RateLimit-Limit`、`X-RateLimit-Remaining`、`X-RateLimit-Reset`（unixタイムスタンプ）。
- 制限を超えた場合は`429`とボディを返します:
```json
{ "success": false, "error": "RATE_LIMIT", "code": "RATE_LIMIT_EXCEEDED", "message": "リクエストが多すぎます。後でもう一度お試しください。", "retryAfter": 30 }
```

---

## 11. キャッシングと条件付きリクエスト
- キャッシュ可能なGETリソースに`Cache-Control`、`ETag`、`Last-Modified`ヘッダーをサポート。
- 適切な場合に`304 Not Modified`を返すために`If-None-Match`をサポート。
- 共有キャッシュにユーザー固有のプライベートデータをキャッシュしない。

---

## 12. 可観測性と監査（非機能要件）
- すべてのリクエストは`X-Request-Id`を伝播/リクエストしてログとトレースを相関させるべきです。
- ログ構造には以下を含める必要があります: `requestId`、`userId`（認証済みの場合）、`endpoint`、`method`、`status`、`latencyMs`。
- 重要な変更を監査: `createdBy`、`updatedBy`、`createdAt`、`updatedAt`、および重要な変更を追跡する`changeLog`を保存。
- エンドポイントリクエスト数、エラー率、レイテンシのメトリクスを公開（Prometheusフレンドリーなメトリクスを推奨）。

---

## 13. 文書化とOpenAPI契約（必須）
- `api-spec/openapi.yaml`（またはjson）でOpenAPI 3.1ドキュメントを維持。OpenAPIは以下のために使用される契約です:
  - クライアントSDK生成
  - フロントエンド用モックサーバー
  - 契約テスト（CI）
  - クイックリファレンス用Swagger UI
- すべての主要リソース（Employee、Department、Qualification、AnnualLeave、Job）の`components.schemas`を含める。
- 各エンドポイントの成功とエラーレスポンスの例を含める。
- `api-spec`を実装と同期させる — CIはOpenAPI検証ステップを実行する必要があります。

---

## 14. テストとCI
- ランタイムAPIをOpenAPI仕様に対して検証する契約テスト（DreddまたはPACT）を追加。
- シリアライゼーション/検証ロジックのユニットテストと重要なフロー（検索、インポート、エクスポート、コンカレンシー）の統合テストを追加。
- CIパイプラインは以下を実行すべきです: lint -> unit tests -> contract tests -> security scan -> deploy (staging)。

---

## 15. 文書化標準（API仕様とドキュメントの書き方）
任意の仕様ファイルとサービスREADMEに以下の最小構造を使用:

**ファイルメタデータヘッダー（すべての仕様ファイルの上部）**
```
# Service / API Title
version: v1.0
date: 2025-10-25
owner: <team or person>
status: draft | review | approved
```

**ディレクトリレイアウト（推奨）**
```
/api-spec/
  openapi.yaml
  employees/
    employees.yaml
    employees_examples.json
/docs/
  README.jp.md
  RESTful_API_Guidelines_v1.1.md
CHANGELOG.md
CONTRIBUTORS.md
```
**文書化ルール**
- 適切な場合は現在時制、命令法を使用（例: "204を返すとき..."）。簡潔に。
- 各エンドポイントのリクエストとレスポンスの例を提供。
- エンドポイントごとに必要な権限とスコープを常に文書化。
- パラメータとステータスコードのリストにテーブルを使用。
- 各エンドポイントに短い「使用法」例と「一般的なエラー」セクションを提供。

---

## 16. API命名とプロパティ規約
- パスセグメント: `kebab-case`（例: `/annual-leaves`）
- JSONキー: `camelCase`（例: `employeeCode`）
- ブールクエリパラメータ: `isActive=true`、`active=1`ではない。
- 主キーに`id`または`uuid`を一貫して使用。使用される形式（integer vs uuid）を文書化。

---

## 17. 例リソーススキーマ（OpenAPIコンポーネントにコピー）
```yaml
Employee:
  type: object
  properties:
    employeeCode:
      type: string
      maxLength: 50
      description: "T_社員マスタからの主キー"
    fullName:
      type: string
      description: "T_社員マスタからの氏名"
    kanaName:
      type: string
      nullable: true
      description: "T_社員マスタからのかな氏名"
    divisionName:
      type: string
      description: "T_社員マスタからの部門名"
    departmentName:
      type: string
      description: "T_社員マスタからの部署名"
    gender:
      type: string
      description: "T_社員マスタからの性別"
    dateOfBirth:
      type: string
      format: date
      description: "T_社員マスタからの生年月日"
    hireDate:
      type: string
      format: date
      description: "T_社員マスタからの入社年月日"
    resignationDate:
      type: string
      format: date
      nullable: true
      description: "T_社員マスタからの退職年月日"
    currentAddress:
      type: string
      nullable: true
      description: "T_社員マスタからの住所1"
    familyAddress:
      type: string
      nullable: true
      description: "T_社員マスタからの住所2"
    mobilePhone:
      type: string
      nullable: true
      description: "T_社員マスタからのTEL携帯用"
    weddingAnniversary:
      type: string
      format: date
      nullable: true
      description: "T_社員マスタからの結婚記念日"
    totalAnnualLeave:
      type: number
      format: float
      description: "T_社員マスタからの年休合計"
    usedAnnualLeave:
      type: number
      format: float
      description: "T_社員マスタからの取得日数"
    remainingAnnualLeave:
      type: number
      format: float
      description: "T_社員マスタからの残日数"
    isRetired:
      type: boolean
      default: false
      description: "退職年月日から計算"
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
      description: "T_統括部門からの部門ID"
    divisionName:
      type: string
      description: "T_統括部門からの統括部門"
    departmentId:
      type: string
      description: "T_部署名からの部署ID"
    departmentName:
      type: string
      description: "T_部署名からの部署名"

Qualification:
  type: object
  properties:
    id:
      type: integer
      description: "T_資格からのID"
    employeeCode:
      type: string
      description: "T_資格からの社員コード"
    qualificationName:
      type: string
      description: "T_資格からの名称"
    grade:
      type: string
      description: "T_資格からの等級"
    type:
      type: string
      description: "T_資格からの種類"
    allowanceAmount:
      type: number
      format: float
      description: "T_資格からの金額"
    certificateNumber:
      type: string
      nullable: true
      description: "T_資格からの番号"
    acquisitionDate:
      type: string
      format: date
      nullable: true
      description: "T_資格からの取得日"
    isChecked:
      type: boolean
      description: "T_資格からのチェック"
```

---

## 18. API変更マージ前のチェックリスト
- [ ] OpenAPI仕様が更新され、`api-spec/`にコミットされました。
- [ ] 仕様にリクエスト/レスポンスの例が含まれています。
- [ ] 説明付きの新しいフィールドが`components.schemas`に追加されました。
- [ ] セキュリティスコープと権限が文書化されました。
- [ ] 契約テストが追加または更新されました。
- [ ] 破壊的変更の移行戦略が文書化されました（非推奨タイムライン）。
- [ ] チェンジログエントリが作成されました（CHANGELOG.md）。
- [ ] QAチェックリストが通過しました（手動テストケースまたは自動統合テスト）。
- [ ] Oracleデータベーススキーマ変更が文書化され、移行スクリプトが提供されました。
- [ ] 日本語文字エンコーディング（UTF-8）処理が検証されました。
- [ ] Oracleシーケンスとトリガー更新がテストされました。

---

## 19. データベーススキーマリファレンス
**Oracleテーブルとリレーションシップ:**
- **T_社員マスタ** (Employee Master) - 主要な社員データテーブル
- **T_統括部門** (Controlling Division) - 高レベル管理部門
- **T_部署名** (Department Names) - 部門IDを介して部門にリンクされた部署名
- **T_資格手当** (Qualification Allowance) - 資格手当のマスタテーブル
- **T_資格** (Qualifications) - T_社員マスタとT_資格手当にリンクされた社員資格
- **T_年休詳細** (Annual Leave Details) - T_社員マスタにリンクされた年次休暇使用詳細
- **T_溶接免許** (Welding License) - 溶接証明書と免許

**主要リレーションシップ:**
- T_部署名.部門ID → T_統括部門.部門ID
- T_資格.社員コード → T_社員マスタ.社員コード
- T_資格.資格ID → T_資格手当.資格ID
- T_年休詳細.社員コード → T_社員マスタ.社員コード

**Oracleシーケンス:**
- SEQ_統括部門_ID, SEQ_資格手当_ID, SEQ_資格_ID, SEQ_年休詳細_ID, SEQ_溶接免許_ID

---

## 20. 貢献者 / 連絡先
- APIオーナー / 連絡先: Chính（または割り当てられたチームリーダー）
- セキュリティオーナー: infra/securityチーム
- QA連絡先: QAリーダー
- データベースオーナー: Oracle DBAチーム
- 簡単な質問については、リポジトリでissueを開くか、内部チャットでオーナーにメッセージを送信してください。

---

## 21. 最終ノート（厳格で一貫性を保つ）
このREADMEは規範的です: 従ってください。一貫性のないAPIは、フロントエンド、自動化、SDKに摩擦を生み、技術的負債を生み出します。このドキュメントで不明確または不足しているものがある場合は、具体的な提案を追加し、OpenAPIスケルトンを更新してPRを開いてください — 仕様を更新せずにアドホックな変更を実装しないでください。

**Oracleデータベース考慮事項:**
- 適切なOracleデータ型（VARCHAR2、NUMBER、DATE）を常に使用
- 日本語文字エンコーディング（UTF-8）を正しく処理
- オートインクリメントフィールドにOracleシーケンスを使用
- Oracle固有の機能（トリガー、制約、インデックス）でテスト
- Oracleパフォーマンス最適化（インデックス、クエリプラン）を考慮

---
