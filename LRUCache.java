class LRUCache extends LinkedHashMap<Integer,Integer> {
    private final int cap;
    LRUCache(int cap){ super(cap,0.75f,true); this.cap=cap; }
    public int get(int k){ return getOrDefault(k,-1); }
    public void put(int k,int v){ super.put(k,v); }
    protected boolean removeEldestEntry(Map.Entry e){ return size()>cap; }
}