# ☁️ AWS — Principal-Level Essentials

## Core Services Cheat Sheet
| Service | Use |
|---|---|
| EC2 | VMs |
| ECS / EKS / Fargate | Containers |
| Lambda | FaaS / glue |
| S3 | Object storage |
| RDS / Aurora | Relational DB |
| DynamoDB | NoSQL key-value |
| MSK | Managed Kafka |
| SQS / SNS | Queue / pub-sub |
| API Gateway | HTTP/REST/WebSocket entry |
| CloudWatch / X-Ray | Logs, metrics, traces |
| Secrets Manager / SSM Parameter Store | Secrets / config |
| IAM | AuthN/Z |
| VPC | Networking |
| Route 53 | DNS |
| CloudFront | CDN |

## Compute Decision
| | Choose when |
|---|---|
| **EC2** | Full control, legacy lift-and-shift |
| **ECS Fargate** | Containers, simple, AWS-native, no node mgmt |
| **EKS Fargate / EC2** | Kubernetes portability, hybrid cloud |
| **Lambda** | Event-driven, sub-15-min jobs |

## RDS vs Aurora
- **Aurora** — AWS-built, 3× faster, 6-way replicated across 3 AZs, auto-scaling storage to 128 TB. Use for high throughput/HA.
- **RDS** — managed standard engines (Postgres, MySQL). Cheaper, simpler.

## MSK vs Self-Managed Kafka
MSK handles broker provisioning, patching, ZooKeeper/KRaft, AZ failover. Self-managed = full control, cheaper at huge scale, more ops burden.

## IAM Best Practices
- Use **roles** for EC2/Lambda/EKS pods (IRSA), never long-lived keys.
- Least privilege; tag-based access (ABAC).
- Enable MFA, CloudTrail, AWS Config.
- Rotate via Secrets Manager (auto for RDS).

## VPC Networking
- Public subnet (ALB/NAT), private subnet (apps/DB).
- **SG** — stateful, instance-level.
- **NACL** — stateless, subnet-level.
- VPC endpoints for S3/DynamoDB to avoid NAT cost.

## Deploying a Spring Boot Service E2E
```
Code → GitHub → CodePipeline / Jenkins
  → mvn build + test
  → docker build + push to ECR
  → kubectl/helm deploy to EKS  (or `aws ecs update-service`)
  → ALB ingress (TLS via ACM)
  → RDS Aurora PostgreSQL (private subnet)
  → MSK for events
  → Secrets Manager (DB creds, rotated)
  → CloudWatch logs/metrics + X-Ray tracing + alarms → SNS → PagerDuty
```

## Auto-Scaling
- EC2/ECS — target tracking (e.g., 60% CPU), step, scheduled.
- K8s — HPA on CPU/mem/custom metrics; **KEDA** for event-driven (Kafka lag, SQS depth).

## Disaster Recovery
| Strategy | RTO | RPO | Cost |
|---|---|---|---|
| Backup & restore | hours | hours | $ |
| Pilot light | 10s of min | minutes | $$ |
| Warm standby | minutes | seconds | $$$ |
| Active-active multi-region | seconds | ~0 | $$$$ |

## S3 Storage Classes
Standard → IA → One Zone-IA → Glacier Instant → Glacier Flexible → Deep Archive. Lifecycle rules transition automatically.

## Cost Optimization
- Reserved Instances / Savings Plans (1–3 yr commits).
- **Spot** for fault-tolerant workloads (up to 90% off).
- Right-size + auto-shutdown dev envs.
- S3 IA / lifecycle to Glacier.
- Delete unattached EBS, EIPs, old snapshots.
- Use VPC endpoints to skip NAT $$$.
- AWS Cost Explorer + Budgets + alerts.