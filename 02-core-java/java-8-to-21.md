# ☕ Java 8 → 21 Highlights

## Streams
- Lazy: intermediate ops (`map`, `filter`) build pipeline, terminal op (`collect`, `forEach`) executes.
- Avoid stateful lambdas; prefer `Collectors.groupingBy`, `partitioningBy`.
- `parallelStream()` only for CPU-bound + large datasets + commutative ops.

## Optional pitfalls
- ❌ Field/parameter type. ✅ Return type.
- `orElseGet(supplier)` over `orElse(value)` for expensive defaults.
- Never `.get()` without `isPresent()`.

## Functional interfaces
| Interface | Signature |
|---|---|
| `Function<T,R>` | T → R |
| `BiFunction<T,U,R>` | (T,U) → R |
| `Supplier<T>` | () → T |
| `Consumer<T>` | T → void |
| `Predicate<T>` | T → boolean |
| `UnaryOperator<T>` | T → T |

## Java 9–17
- **Modules** (9), `var` (10), `HttpClient` (11), `switch` expressions (14), **Records** (16), **Sealed classes** (17), pattern matching for `instanceof` & `switch`.

```java
record Money(BigDecimal amount, Currency ccy) {}
sealed interface Shape permits Circle, Square {}
String s = switch (obj) {
    case Integer i -> "int " + i;
    case String  x -> "str " + x;
    default        -> "other";
};
```

## Java 21 (LTS)
- **Virtual threads** (`Thread.ofVirtual().start(...)`, `Executors.newVirtualThreadPerTaskExecutor()`).
- **Sequenced collections** (`getFirst`, `getLast`).
- **Pattern matching for switch** (final).
- **Record patterns**: `if (p instanceof Point(int x, int y)) ...`.