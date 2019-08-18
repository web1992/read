# Spring IOC

This chapter covers the Spring Framework implementation of the Inversion of Control (`IoC`)  principle.
IoC is also known as dependency injection (`DI`). It is a process whereby objects define their
dependencies, that is, the other objects they work with, only through constructor arguments, arguments
to a factory method, `or properties that are set on the object instance after it is constructed or returned
from a factory method`. __The `container` then `injects` those dependencies when it creates the bean. This
process is fundamentally the inverse, hence the name Inversion of Control (`IoC`), of the bean itself
controlling the instantiation or location of its dependencies by using direct construction of classes, or a
mechanism such as the Service Locator pattern__.

> Spring 会搜集所有的`Bean`，在使用`Bean`创建对象的时候，会注入这个`Bean`所依赖的对象，而无需你自己去`new`对象
> Spring 容器帮你做了这个new 这个步骤
