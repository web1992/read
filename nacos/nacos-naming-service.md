# NamingService

```java
NamingService naming = NamingFactory.createNamingService(System.getProperty("serveAddr"));
naming.registerInstance("nacos.test.3", "11.11.11.11", 8888, "TEST1");
```