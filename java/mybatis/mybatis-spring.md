# mybatis spring

- [https://github.com/mybatis/spring](https://github.com/mybatis/spring)

## config

```xml
<!-- SqlSessionFactory -->
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
    <property name="dataSource" ref="druidDataSource"/>
    <property name="typeAliasesPackage" value="com.xxx"/>
    <property name="configLocation" value="classpath:/config/mybatis/mybatis-config.xml"/>
</bean>
<!-- ScanMapperFiles -->
<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
    <property name="basePackage" value="com.xxx"/>
    <property name="markerInterface" value="com.xxx.common.dao.BaseDao"/>
</bean>
```

## MapperScannerConfigurer

`org.mybatis.spring.mapper.MapperScannerConfigurer`

## SqlSessionFactoryBean

`org.mybatis.spring.SqlSessionFactoryBean`
