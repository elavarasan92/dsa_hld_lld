@Service @RequiredArgsConstructor
public class OrderService {
  private final OrderRepo orders;
  private final OutboxRepo outbox;

  @Transactional  // single DB tx
  public Order create(OrderRequest req) {
    Order o = orders.save(new Order(req));
    outbox.save(new OutboxEvent(
        "order-events", o.getId().toString(),
        toJson(new OrderCreated(o)), Instant.now()));
    return o;
  }
}
// A separate poller (or Debezium CDC on outbox table) ships rows → Kafka, then deletes them.