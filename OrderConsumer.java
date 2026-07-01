@KafkaListener(topics = "order-events", groupId = "fulfilment",
               containerFactory = "manualAckFactory")
public void onMessage(ConsumerRecord<String, OrderEvent> rec, Acknowledgment ack) {
  try {
    fulfilmentService.handle(rec.value());
    ack.acknowledge();
  } catch (TransientException e) {
    throw e; // let DefaultErrorHandler retry with backoff
  } catch (Exception poison) {
    dlq.send("order-events.DLT", rec.key(), rec.value()); // DLQ
    ack.acknowledge();
  }
}

@Bean
public DefaultErrorHandler errorHandler(KafkaTemplate<?,?> t) {
  var recoverer = new DeadLetterPublishingRecoverer(t,
      (r, e) -> new TopicPartition(r.topic() + ".DLT", r.partition()));
  return new DefaultErrorHandler(recoverer,
      new ExponentialBackOffWithMaxRetries(5)); // 5 retries
}