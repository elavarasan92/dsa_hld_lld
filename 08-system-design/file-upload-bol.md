# 📄 System Design — Bill of Lading Upload Service

## 1. Requirements
- Customers/agents upload BoL PDFs/images.
- Virus scan + OCR + metadata extraction.
- Searchable by booking #, container #, vessel.
- Retention 7 years (regulatory).
- File size up to 50 MB.
- 1K uploads/day, peak 50/min.

## 2. APIs
```
POST /v1/documents/upload-url       → returns presigned S3 PUT URL + uploadId
POST /v1/documents/{uploadId}/complete
GET  /v1/documents/{id}             → metadata + presigned GET URL
GET  /v1/documents?bookingId=...
```

## 3. HLD
```
Client → API → presigned S3 URL (skip server bandwidth)
   → Client uploads directly to S3 (bucket: hl-bol-uploads)
   → S3 Event (ObjectCreated) → SQS → Processor (ECS)
        1. Virus scan (Lambda + ClamAV layer / GuardDuty Malware Protection)
        2. If clean → move to bucket: hl-bol-clean
           If infected → quarantine bucket + alert
        3. AWS Textract → extract text + form fields
        4. Persist Document(id, bookingId, s3Key, status, ocrText, metadata) in PostgreSQL
        5. Index searchable fields in OpenSearch
        6. Emit DocumentReady event (Kafka)
```

## 4. Data Model
```sql
document(id PK, booking_id, container_id, s3_key, status, mime, size,
         uploaded_by, uploaded_at, ocr_text, metadata jsonb, version)
audit_log(id, document_id, action, actor, ts)  -- immutable
```
- `metadata` jsonb GIN-indexed.
- OpenSearch index for full-text search on `ocr_text`.

## 5. Security
- Presigned URLs scoped: PUT-only, content-type pinned, max size, 5-min TTL.
- S3 bucket: encryption at rest (KMS), public access blocked, versioning, **Object Lock (compliance mode)** for 7-year retention.
- Audit every read (CloudTrail data events).
- Access control: signed URLs gated by app-level authz (booking owner, admin role).

## 6. Reliability
- SQS retry + DLQ on processor failure.
- Idempotent processor: keyed by `s3 ETag`.
- OCR failures → flag for manual review queue.

## 7. Observability
- Upload success rate, virus hits, OCR latency, indexing lag.
- Alert on quarantine bucket size growth.

## 8. Trade-offs
- Direct-to-S3 upload (cheaper, scalable) vs through-app (easier validation).
- Textract (managed, $$) vs Tesseract (free, lower accuracy) — Textract for Bills of Lading.
- OpenSearch (search) vs PostgreSQL FTS (cheaper, simpler) — chose OpenSearch for relevance + scale.