# 📣 System Design — Notification Service

## 1. Requirements
- Multi-channel: Email (SES), SMS (SNS/Twilio), Push (FCM/APNs), WebSocket.
- Templated messages, i18n.
- Per-user preferences (channel, quiet hours, opt-out).
- Retry on transient failure → DLQ on permanent.
- 100K notifications/day, 5K/sec burst.
- At-least-once delivery; dedupe on client side.

## 2. APIs
```
POST /v1/notifications              { userId, templateId, params, channels[] }
GET  /v1/notifications/{id}
GET  /v1/users/{id}/preferences
PUT  /v1/users/{id}/preferences
```

## 3. HLD
```
Producers (Booking, Container, Pricing, ...) 
   → Kafka topic: notification-requests (key=userId)
   → Notification Service:
       1. Load user prefs (Redis cache, fallback DB)
       2. Apply quiet hours / opt-out
       3. Render template (Handlebars, locale-aware)
       4. Fan-out to channel queues:
            email-queue (SQS) → Email Worker → SES
            sms-queue   (SQS) → SMS Worker   → SNS/Twilio
            push-queue  (SQS) → Push Worker  → FCM/APNs
            ws-queue    (SQS) → WS Gateway   → connected clients
       5. Persist NotificationLog (status per channel)
       6. Retry with backoff; DLQ after N attempts
```

## 4. Data Model
```sql
notification(id PK, user_id, template_id, params jsonb, status, created_at)
delivery_attempt(id PK, notification_id FK, channel, status, error, attempt_no, ts)
user_preference(user_id PK, email bool, sms bool, push bool, quiet_from time, quiet_to time, locale, timezone)
template(id PK, channel, locale, subject, body)
```

## 5. Templates
- Stored in DB or S3, versioned.
- Rendered server-side; sanitize inputs (XSS).
- A/B testing field on template.

## 6. Reliability
- **Idempotency**: `notificationId` deduped at consumer.
- **Retry**: exponential backoff (1s, 5s, 30s, 5m, 1h).
- **DLQ**: poisoned templates / permanent fails (invalid email).
- **Circuit breaker** on upstream provider failures.

## 7. Observability
- Per-channel metrics: send rate, success %, p95 latency, retry count, DLQ rate.
- Trace from producer → notification → channel provider.

## 8. Trade-offs
- One service per channel (microservice purist) vs single service with channel workers — chose latter for simplicity at this scale.
- Provider abstraction layer to swap SES → SendGrid easily.
- Push tokens stored encrypted; rotate on app reinstall.