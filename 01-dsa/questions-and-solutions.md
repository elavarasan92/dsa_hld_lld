# 🧩 DSA — Principal-Level Questions & Solutions

At Principal level, focus is **production-quality code**, not LeetCode hard.

---

## 1. First Non-Repeating Char in a Stream
Use `LinkedHashMap` for insertion order + counts. First entry with count==1 is answer.

```java
class FirstUnique {
    private final LinkedHashMap<Character,Integer> map = new LinkedHashMap<>();
    public Character add(char c) {
        map.merge(c, 1, Integer::sum);
        return map.entrySet().stream()
                .filter(e -> e.getValue() == 1)
                .findFirst().map(Map.Entry::getKey).orElse(null);
    }
}
```

## 2. LRU Cache
```java
class LRUCache<K,V> extends LinkedHashMap<K,V> {
    private final int cap;
    public LRUCache(int cap){ super(cap, 0.75f, true); this.cap = cap; }
    @Override protected boolean removeEldestEntry(Map.Entry<K,V> e){ return size() > cap; }
}
```
**From scratch**: HashMap + Doubly Linked List → O(1) get/put.

## 3. Token Bucket Rate Limiter
```java
class TokenBucket {
    private final long capacity, refillPerSec;
    private double tokens; private long lastNanos;
    TokenBucket(long cap, long rps){ capacity=cap; refillPerSec=rps; tokens=cap; lastNanos=System.nanoTime(); }
    synchronized boolean tryAcquire(){
        long now = System.nanoTime();
        tokens = Math.min(capacity, tokens + (now-lastNanos)/1e9 * refillPerSec);
        lastNanos = now;
        if (tokens >= 1){ tokens--; return true; }
        return false;
    }
}
```

## 4. Producer-Consumer
```java
BlockingQueue<Task> q = new LinkedBlockingQueue<>(100);
// producer: q.put(t);  consumer: Task t = q.take();
```

## 5. Top-K Frequent
```java
Map<String,Integer> freq = ...;
PriorityQueue<Map.Entry<String,Integer>> heap =
    new PriorityQueue<>(Comparator.comparingInt(Map.Entry::getValue));
freq.entrySet().forEach(e -> { heap.offer(e); if (heap.size() > k) heap.poll(); });
```
O(N log K).

## 6. Merge K Sorted Lists
```java
PriorityQueue<ListNode> pq = new PriorityQueue<>(Comparator.comparingInt(n -> n.val));
for (ListNode h : lists) if (h != null) pq.offer(h);
ListNode dummy = new ListNode(0), cur = dummy;
while (!pq.isEmpty()){
    ListNode n = pq.poll(); cur.next = n; cur = n;
    if (n.next != null) pq.offer(n.next);
}
return dummy.next;
```

## 7. KV Store with TTL
```java
class TTLCache<K,V> {
    record Entry<V>(V value, long expiry){}
    private final Map<K,Entry<V>> map = new ConcurrentHashMap<>();
    public void put(K k, V v, long ttlMs){ map.put(k, new Entry<>(v, System.currentTimeMillis()+ttlMs)); }
    public V get(K k){
        Entry<V> e = map.get(k);
        if (e == null) return null;
        if (e.expiry < System.currentTimeMillis()){ map.remove(k); return null; }
        return e.value;
    }
}
```

## 8. Word Frequency on Huge File
```java
ConcurrentMap<String, LongAdder> counts = new ConcurrentHashMap<>();
Files.lines(Paths.get(path)).parallel()
     .flatMap(l -> Arrays.stream(l.toLowerCase().split("\\W+")))
     .filter(w -> !w.isEmpty())
     .forEach(w -> counts.computeIfAbsent(w, k -> new LongAdder()).increment());
```

---

## Other classics to skim
- Reverse linked list (iterative + recursive)
- Detect cycle (Floyd's)
- Valid parentheses (stack)
- BST validation, LCA, level-order traversal
- Binary search variants (rotated array, first/last occurrence)
- Coin change, climbing stairs (DP basics)
- BFS/DFS on graph; cycle detection