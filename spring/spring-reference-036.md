# Cache Abstraction

## Introduction

`org.springframework.cache.Cache`
`org.springframework.cache.CacheManager`

## Important

> Obviously this approach works only for methods that are guaranteed to return the same output (result) for a given input (or arguments) no matter how many times it is being executed.

## cache multi-process environment

> The caching abstraction has no special handling of multi-threaded and multi-process environments as such features are handled by the cache implementation.

If you have a multi-process environment (i.e. an application deployed on several nodes), you will need to configure your cache provider accordingly. Depending on your use cases, a copy of the same data on several nodes may be enough but if you change the data during the course of the application, you may need to enable other propagation mechanisms.

Caching a particular item is a direct equivalent of the typical get-if-not-found-then- proceed-and-put-eventually code blocks found with programmatic cache interaction: no locks are applied and several threads may try to load the same item concurrently. The same applies to eviction: if several threads are trying to update or evict data concurrently, you may use stale data. Certain cache providers offer advanced features in that area, refer to the documentation of the cache provider that you are using for more details.

To use the cache abstraction, the developer needs to take care of two aspects:

caching declaration - identify the methods that need to be cached and their policy
cache configuration - the backing cache where the data is stored and read from

## Declarative annotation-based caching

For caching declaration, the abstraction provides a set of Java annotations:

- @Cacheable triggers cache population
- @CacheEvict triggers cache eviction
- @CachePut updates the cache without interfering with the method execution
- @Caching regroups multiple cache operations to be applied on a method
- @CacheConfig shares some common cache-related settings at class-level

Let us take a closer look at each annotation:

### Cacheable

```java
@Cacheable("books")
public Book findBook(ISBN isbn) {...}
```

### Default Key Generation

`KeyGenerator`
`SimpleKey`

### Custom Key Generation Declaration

### Default Cache Resolution

`org.springframework.cache.interceptor.CacheResolver`

### CachePut annotation

```java
// @CachePut is for update chache
// not use @Cacheable  with @CachePut
@CachePut(cacheNames="book", key="#isbn")
public Book updateBook(ISBN isbn, BookDescriptor descriptor)
```

### CacheEvict annotation