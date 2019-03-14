# Router

## RouterFactory

```java
@SPI
public interface RouterFactory {

    @Adaptive("protocol")
    Router getRouter(URL url);
}
```