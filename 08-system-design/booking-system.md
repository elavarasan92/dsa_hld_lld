# 📦 System Design — Hapag-Lloyd Online Booking

## 1. Requirements
**Functional**
- Customer searches schedule (origin/dest/date).
- Get quote (rate engine).
- Create booking (cargo, container type, dates).
- Pay or invoice.
- Receive Bill of Lading.
- Modify / cancel.

**Non-Functional**
- 5K bookings/day, peak 50/sec at launch dates.
- p99 booking POST < 1 s.
- Strong consistency on booking + container reservation.
- 99.9% availability.

## 2. Bounded Contexts (Microservices)
- **Search** (read-heavy, cached schedules)
- **Quote** (rate engine)
- **Booking** (write-heavy, transactional)
- **Inventory** (container & slot availability)
- **Payment**
- **Document** (BoL generation, S3)
- **Notification**

## 3. APIs
```
POST /v1/bookings           Idempotency-Key: <uuid>
GET  /v1/bookings/{id}
PATCH /v1/bookings/{id}
DELETE /v1/bookings/{id}
GET  /v1/schedules?from=&to=&date=
POST /v1/quotes
```

## 4. Data Model (Booking service, PostgreSQL)
```sql
booking(id PK, customer_id, status, origin, dest, etd, eta, total, version, created_at, updated_at)
booking_container(id PK, booking_id FK, container_type, qty, weight)
outbox(id PK, topic, key, payload jsonb, created_at, processed_at)
idempotency(key PK, response jsonb, created_at)
```

## 5. HLD
```
UI/API consumer → API Gateway (auth, rate limit, idempotency)
                 → Booking Service (Spring Boot)
                    ├─ PostgreSQL (Aurora)
                    └─ Outbox table
                       ↓ Debezium CDC
                       Kafka topic: booking-events
                          ├─ Inventory Service (reserve container) → emits ContainerReserved
                          ├─ Payment Service (charge / invoice)    → emits PaymentSucceeded
                          ├─ Document Service (BoL → S3)           → emits BoLIssued
                          └─ Notification Service (email/SMS)
Saga coordinator (Booking) consumes events, advances state machine.
```

## 6. Saga (Orchestration in Booking service)
```
States: CREATED → INVENTORY_RESERVED → PAID → BOL_ISSUED → CONFIRMED
                                       ↘ FAILED → COMPENSATING → CANCELLED
```
Compensations:
- Payment fail → release container.
- BoL gen fail → refund + release.

## 7. Idempotency
- API Gateway/Service stores `Idempotency-Key` → response for 24 h.
- Replays return original response, never re-execute side effects.

## 8. Consistency
- Booking + Outbox in **same DB tx** (atomic).
- Cross-service consistency via **Saga + events**.
- Inventory reservation uses optimistic lock (`@Version`) on slot row.

## 9. Failure Handling
- Kafka consumer retries with backoff → DLQ.
- Saga timeouts → compensation.
- Payment provider down → queue + retry; user sees `PENDING_PAYMENT`.

## 10. Cross-cutting
- **Auth**: OIDC via API Gateway, JWT.
- **Observability**: trace ID propagated through Saga events.
- **Audit**: every state transition appended to immutable audit log (S3 Object Lock).
- **GDPR**: customer data minimization, right-to-erasure handled by anonymization (cannot delete booking — financial record).
- **Multi-region**: Aurora global DB, active-passive failover.

## 11. Trade-offs
- Saga orchestration (visible, easier ops) over choreography.
- PostgreSQL outbox + Debezium over dual-write or 2PC.
- Strong consistency only inside Booking; eventual across services.