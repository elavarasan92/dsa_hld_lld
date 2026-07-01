# 🚀 DevOps & CI/CD

## Sample Jenkinsfile (Declarative)
```groovy
pipeline {
  agent any
  options { timeout(time: 30, unit: 'MINUTES'); disableConcurrentBuilds() }
  environment { IMG = "registry.hl.com/booking-svc" }
  stages {
    stage('Build')   { steps { sh 'mvn -B clean package -DskipTests' } }
    stage('Test')    { steps { sh 'mvn test' } }
    stage('Sonar')   { steps { withSonarQubeEnv('sonar') { sh 'mvn sonar:sonar' } } }
    stage('Quality') { steps { timeout(5){ waitForQualityGate abortPipeline: true } } }
    stage('Docker')  { steps { sh "docker build -t $IMG:$BUILD_NUMBER ." ; sh "docker push $IMG:$BUILD_NUMBER" } }
    stage('Deploy')  { steps { sh "kubectl set image deploy/booking-svc app=$IMG:$BUILD_NUMBER -n prod" } }
  }
  post {
    failure { mail to: 'team@hl.com', subject: "Build #${BUILD_NUMBER} failed" }
  }
}
```

## Docker Best Practices
- **Multi-stage builds**: build in JDK image, copy jar to JRE/distroless.
- Order Dockerfile: dependencies first, code last → cache friendly.
- Pin base image versions; scan with Trivy.
- Run as non-root.

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java","-XX:+UseG1GC","-jar","/app/app.jar"]
```

## Kubernetes Essentials
| Object | Purpose |
|---|---|
| Pod | smallest unit (1+ containers) |
| Deployment | replicas + rolling updates |
| StatefulSet | stable identity (Kafka, DBs) |
| Service | stable network identity (ClusterIP/NodePort/LoadBalancer) |
| ConfigMap | non-secret config |
| Secret | sensitive config |
| Ingress | HTTP routing + TLS |
| HPA | autoscale on CPU/mem/custom |
| PodDisruptionBudget | safe drain during updates |

## Probes
- **Liveness** — restart if dead.
- **Readiness** — remove from LB until ready.
- **Startup** — for slow-start apps; gates the others.

```yaml
livenessProbe:  { httpGet: { path: /actuator/health/liveness,  port: 8080 }, periodSeconds: 10 }
readinessProbe: { httpGet: { path: /actuator/health/readiness, port: 8080 }, periodSeconds: 5  }
startupProbe:   { httpGet: { path: /actuator/health,           port: 8080 }, failureThreshold: 30 }
```

## Deployment Strategies
| Strategy | When |
|---|---|
| Rolling | safe default |
| Blue-Green | zero-downtime, instant rollback (2× cost) |
| Canary | gradual % traffic to new version (best with mesh / Argo Rollouts) |

## GitOps
- Git is the source of truth.
- **ArgoCD / Flux** continuously reconcile cluster state to Git.
- Auditable, rollback = `git revert`.

## Branching
- **Trunk-based** preferred for CI/CD: short-lived branches, daily merges, feature flags.
- GitFlow only when long release cycles.

## Quality Gates
- SonarQube: bugs, vulnerabilities, code smells, coverage %.
- OWASP Dependency-Check / Snyk for libs.
- Trivy for container images.
- Fail build on threshold breach.

## Secrets
- Never commit. Use Vault / AWS Secrets Manager / SealedSecrets / SOPS.
- Inject via env vars or mounted files.
- Rotate regularly; alert on age.

## Observability Stack (sample)
- Logs → Fluent Bit → Loki / CloudWatch.
- Metrics → Prometheus → Grafana.
- Traces → OpenTelemetry → Tempo / Jaeger / X-Ray.
- Alerts → Alertmanager → PagerDuty / Slack.