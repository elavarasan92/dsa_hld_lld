# 👥 Managerial / Director IT Round — STAR Stories

Frame all answers using **S**ituation → **T**ask → **A**ction → **R**esult.

---

## 1. Mentoring a struggling engineer
**S**: A junior engineer joined our team and was failing code reviews repeatedly due to inconsistent design decisions and weak testing.
**T**: Bring him to the team's quality bar within one quarter.
**A**: I paired with him 2 hrs/week, walked through SOLID principles using our actual codebase, gave him a small refactor task, then a feature, then a complex bug — escalating ownership. I also paired him with a senior on rotation.
**R**: Within 3 months he was reviewing PRs himself; within 6 months he led a small feature end-to-end. He's now a tech lead.

## 2. Leading an architectural decision
**S**: Our monolithic order service was bottlenecking deploys and incidents.
**T**: Decide whether to extract microservices and how.
**A**: Wrote an ADR comparing 3 options (modular monolith, event-driven extraction, full rewrite). Built a 1-week POC of the strangler-fig approach using Kafka outbox. Presented trade-offs with cost & timeline to leadership.
**R**: We extracted 4 services over 6 months with zero downtime; deploy frequency went from weekly to multiple per day; MTTR dropped 60%.

## 3. Production incident
**S**: Saturday 3 AM PagerDuty: order-fulfilment Kafka consumer lag spiked to 2 hours; customers couldn't see order status.
**T**: Restore SLO, then RCA.
**A**: Opened incident channel, scaled consumers from 4 → 12. Identified slow `findByCustomer` query (missing composite index). Hot-fixed index in production with `CREATE INDEX CONCURRENTLY`. Lag drained in 40 min. Wrote blameless post-mortem the next day; added: (a) consumer-lag SLO with 5-min alert, (b) p99 query latency alert, (c) code review checklist item for query plans.
**R**: Same class of incident has not recurred in 18 months; team adopted the SLO across other services.

## 4. Tech debt vs feature delivery
**S**: PM was pushing 100% sprint capacity to features; tech debt was eroding velocity.
**T**: Negotiate sustainable balance.
**A**: Quantified debt: 30% of incident hours and 25% of dev time was firefighting. Built a "debt impact dashboard" tying debt items to velocity and incident metrics. Proposed a 70/20/10 split (features/debt/exploration).
**R**: Velocity (in delivered story points) increased 35% over 2 quarters because debt items unblocked feature work. PM became an advocate for the model.

## 5. Hamburg ↔ Chennai collaboration
**S**: Joint project across Hamburg (architects) and Chennai (devs) was missing deadlines due to time-zone delays.
**T**: Improve velocity without burning anyone out.
**A**: Implemented: (a) **written-first** culture — all decisions via ADRs/RFCs in Git, (b) overlap window 2–4 PM IST / 10 AM–12 PM CET for live syncs, (c) async standups via Slack, (d) rotation of meeting time so no team always sacrificed evenings, (e) recorded all design discussions.
**R**: Deadline slip went from 30% to <5%; team satisfaction (anonymous survey) up 40%.

## 6. Disagreement with peer
**S**: Senior architect insisted on gRPC for all inter-service calls; I felt REST was better for our use case.
**T**: Resolve without political damage.
**A**: Proposed a 2-day spike measuring latency, dev velocity, and tooling for both protocols on our actual workload. Presented data jointly.
**R**: Adopted REST for external + gRPC for high-throughput internal — better than either single answer. Strengthened working relationship.

## 7. Onboarding new hires
**A**: Buddy system, "first PR within 3 days" task, runbook reading list, architecture walkthrough video, shadow on-call from week 2, retro after 30 days.
**R**: Time to first independent feature dropped from 6 weeks to 3.

## 8. Driving best practices
**A**: Started a weekly Friday "Tech Hour" — rotating presenter, 30 min topic. Examples: virtual threads, Kafka exactly-once, AWS cost optimization.
**R**: Knowledge spread organically; 4 new internal tools came out of these sessions.

## 9. Stay updated
**A**: ThoughtWorks Tech Radar quarterly review, InfoQ newsletter, Devoxx & KubeCon conferences, AWS re:Invent recordings, side POCs (last: virtual threads benchmark on a real microservice).

## 10. "Why Hapag-Lloyd?" answer
> *"Three reasons. First, the impact: container shipping moves 80% of world trade — software here moves the physical economy, not just bits. Second, the technology: your stack — Java, Kafka, AWS, PostgreSQL, Kubernetes — is exactly where my expertise sits, and you're investing in modernization (FIS3, Quick Quotes, Live Position). Third, the people: the Hamburg–Chennai dual-hub model gives me global exposure and lets me mentor a growing engineering team. As a Principal, I want to build systems that will outlast me, and Hapag-Lloyd's 175-year history tells me you think the same way."*

---

## Quick-fire behavioural prompts to rehearse
- Toughest bug you've fixed?
- Time you said no to a stakeholder?
- Time you changed your mind?
- Failure you owned?
- Decision made with incomplete info?
- Underperformer you helped — or had to let go?