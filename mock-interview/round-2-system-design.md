# 🎙️ Mock Interview — Round 2: System Design

## Prompt
> *"Design Hapag-Lloyd's Online Booking System."*

You have **60 minutes**. Use whiteboard / Miro / paper.

## Suggested Time Budget
| Minutes | Phase |
|---|---|
| 0–5 | Clarify requirements |
| 5–10 | Capacity estimation |
| 10–15 | API design |
| 15–25 | HLD diagram |
| 25–40 | Deep dive (Saga + outbox + idempotency) |
| 40–50 | Failure modes + observability + security |
| 50–55 | Trade-offs |
| 55–60 | Bonus / questions |

## Clarifying Questions to Ask
- B2B (forwarders) or B2C (small shippers) or both?
- Volume: bookings/day, peak concurrency?
- Geographies / multi-region?
- Payment: prepay or invoice?
- Modify/cancel allowed? Up to when?
- Integration with existing legacy systems?
- Compliance: GDPR, customs, financial aud
