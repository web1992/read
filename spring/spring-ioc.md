# Spring IOC

This chapter covers the Spring Framework implementation of the Inversion of Control (IoC) 1 principle.
IoC is also known as dependency injection (DI). It is a process whereby objects define their
dependencies, that is, the other objects they work with, only through constructor arguments, arguments
to a factory method, `or properties that are set on the object instance after it is constructed or returned
from a factory method`. __The container then `injects` those dependencies when it creates the bean. This
process is fundamentally the inverse, hence the name Inversion of Control (IoC), of the bean itself
controlling the instantiation or location of its dependencies by using direct construction of classes, or a
mechanism such as the Service Locator pattern__.
