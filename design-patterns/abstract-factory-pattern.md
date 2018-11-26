# Abstract factory pattern

- [Abstract factory pattern](https://en.wikipedia.org/wiki/Abstract_factory_pattern)

## Definition

The essence of the Abstract Factory Pattern is to "Provide an interface for creating _families_ of related or dependent objects without specifying their concrete classes".

## The Abstract Factory design pattern solves problems like:

- How can an application be independent of how its objects are created?
- How can a class be independent of how the objects it requires are created?
- How can families of related or dependent objects be created?

## The Abstract Factory design pattern describes how to solve such problems

- Encapsulate object creation in a separate (factory) object. That is, define an interface (AbstractFactory) for creating objects, and implement the interface.
- A class delegates object creation to a factory object instead of creating objects directly.

This makes a class independent of how its objects are created (which concrete classes are instantiated). A class can be configured with a factory object, which it uses to create objects, and even more, the factory object can be exchanged at run-time.
