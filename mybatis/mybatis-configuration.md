# Configuration

`org.apache.ibatis.session.Configuration`

## parseConfiguration

```java
private void parseConfiguration(XNode root) {
    try {
      propertiesElement(root.evalNode("properties")); //issue #117 read properties first
      typeAliasesElement(root.evalNode("typeAliases"));
      pluginElement(root.evalNode("plugins"));
      objectFactoryElement(root.evalNode("objectFactory"));
      objectWrapperFactoryElement(root.evalNode("objectWrapperFactory"));
      settingsElement(root.evalNode("settings"));
      environmentsElement(root.evalNode("environments"));
      databaseIdProviderElement(root.evalNode("databaseIdProvider"));
      typeHandlerElement(root.evalNode("typeHandlers"));
      mapperElement(root.evalNode("mappers"));
    } catch (Exception e) {
      throw new BuilderException("Error parsing SQL Mapper Configuration. Cause: " + e, e);
    }
}
```

## Configuration construct

```java
public Configuration() {
  typeAliasRegistry.registerAlias("JDBC", JdbcTransactionFactory.class.getName());
  typeAliasRegistry.registerAlias("MANAGED", ManagedTransactionFactory.class.getName());
  typeAliasRegistry.registerAlias("JNDI", JndiDataSourceFactory.class.getName());
  typeAliasRegistry.registerAlias("POOLED", PooledDataSourceFactory.class.getName());
  typeAliasRegistry.registerAlias("UNPOOLED", UnpooledDataSourceFactory.class.getName());

  typeAliasRegistry.registerAlias("PERPETUAL", PerpetualCache.class.getName());
  typeAliasRegistry.registerAlias("FIFO", FifoCache.class.getName());
  typeAliasRegistry.registerAlias("LRU", LruCache.class.getName());
  typeAliasRegistry.registerAlias("SOFT", SoftCache.class.getName());
  typeAliasRegistry.registerAlias("WEAK", WeakCache.class.getName());

  typeAliasRegistry.registerAlias("VENDOR", VendorDatabaseIdProvider.class.getName());
}
```
