@Configuration
public class KafkaProducerConfig {
  @Bean
  public ProducerFactory<String, OrderEvent> pf() {
    Map<String,Object> p = new HashMap<>();
    p.put(BOOTSTRAP_SERVERS_CONFIG, "broker:9092");
    p.put(KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    p.put(VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
    p.put(ENABLE_IDEMPOTENCE_CONFIG, true);          // dedup retries
    p.put(ACKS_CONFIG, "all");                       // durability
    p.put(MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5); // ordering OK with idempotence
    p.put(RETRIES_CONFIG, Integer.MAX_VALUE);
    p.put(TRANSACTIONAL_ID_CONFIG, "order-tx-" + InetAddress.getLocalHost().getHostName());
    return new DefaultKafkaProducerFactory<>(p);
  }
  @Bean public KafkaTemplate<String,OrderEvent> kt(ProducerFactory<String,OrderEvent> pf){
    KafkaTemplate<String,OrderEvent> t = new KafkaTemplate<>(pf);
    t.setTransactionIdPrefix("order-tx-");
    return t;
  }
}