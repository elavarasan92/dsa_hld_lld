# 📨 Kafka — Production Code Samples (Spring Boot)

## 1. Idempotent + Transactional Producer
```java
@Configuration
public class KafkaProducerConfig {
    @Bean
    public ProducerFactory<String, OrderEvent> pf() throws Exception {
        Map<String,Object> p = new HashMap<>();
        p.put(BOOTSTRAP_SERVERS_CONFIG, "broker:9092");
        p.put(KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        p.put(VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
        p.put(ENABLE_IDEMPOTENCE_CONFIG, true);
        p.put(ACKS_CONFIG, "all");
        p.put(MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5);
        p.put(RETRIES_CONFIG, Integer.MAX_VALUE);
        p.put(TRANSACTIONAL_ID_CONFIG, "order-tx-" + InetAddress.getLocalHost().getHostName());
        return new DefaultKafkaProducerFactory<>(p);
    }
    @Bean
    public KafkaTemplate<String,OrderEvent> kt(ProducerFactory<String,OrderEvent> pf){
        KafkaTemplate<String,OrderEvent> t = new KafkaTemplate<>(pf);
        t.setTransactionIdPrefix("order-tx-");
        return t;
    }
}
```

## 2. Outbox Pattern
```java
@Service @RequiredArgsConstructor
public class OrderService {
    private final OrderRepo orders;
    private final OutboxRepo outbox;

    @Transactional
    public Order create(OrderRequest req) {
        Order o = orders.save(new Order(req));
        outbox.save(new OutboxEvent(
            "order-events",
            o.getId().toString(),
            toJson(new OrderCreated(o)),
            Instant.now()));
        return o;
    }
}
// Debezium CDC on `outbox` table → Kafka. Or scheduled poller deletes after publish.
```

## 3. Consumer with DLQ + Retry
```java
@Configuration
@EnableKafka
public class KafkaConsumerConfig {

    @Bean
    public DefaultErrorHandler errorHandler(KafkaTemplate<Object,Object> t) {
        var recoverer = new DeadLetterPublishingRecoverer(t,
            (r, e) -> new TopicPartition(r.topic() + ".DLT", r.partition()));
        var backoff = new ExponentialBackOffWithMaxRetries(5);
        backoff.setInitialInterval(500);
        backoff.setMultiplier(2.0);
        backoff.setMaxInterval(10_000);
        var handler = new DefaultErrorHandler(recoverer, backoff);
        handler.addNotRetryableExceptions(IllegalArgumentException.class);
        return handler;
    }
}

@Component
public class OrderConsumer {
    @KafkaListener(topics = "order-events", groupId = "fulfilment")
    public void handle(ConsumerRecord<String, OrderEvent> rec) {
        fulfilmentService.handle(rec.value());
    }
}
```

## 4. Static Membership (avoid rebalance storms)
```yaml
spring.kafka.consumer.properties:
  group.instance.id: ${HOSTNAME}
  partition.assignment.strategy: org.apache.kafka.clients.consumer.CooperativeStickyAssignor
  session.timeout.ms: 45000
  max.poll.interval.ms: 300000
  enable.auto.commit: false
spring.kafka.listener.ack-mode: RECORD
```

## 5. Kafka Streams — Geo-Fence
```java
@Bean
public KStream<String, ContainerEvent> containerFlow(StreamsBuilder b) {
    KStream<String, ContainerEvent> events = b.stream("container-events");
    events.filter((k, v) -> insideRestrictedZone(v.lat(), v.lon()))
          .mapValues(v -> new GeoAlert(v.containerId(), "ENTERED_RESTRICTED", v.ts()))
          .to("geo-alerts");
    return events;
}
```

## 6. Idempotent Consumer (dedup table)
```java
@Transactional
public void handle(OrderEvent ev) {
    if (processedRepo.existsById(ev.id())) return;     // dedup
    fulfil(ev);
    processedRepo.save(new Processed(ev.id(), Instant.now()));
}
```

## 7. Pitfalls Cheat Sheet
| Issue | Fix |
|---|---|
| Consumer lag growing | scale consumers ≤ partitions; profile handler |
| Out-of-order processing | key by entity id; one partition per key |
| Duplicate processing | idempotent consumer (dedup table) |
| Slow rebalance | static membership + cooperative assignor |
| Large messages | compress (`lz4`); store payload in S3 + send pointer |
| `RecordTooLargeException` | tune `max.request.size`, broker `message.max.bytes` |