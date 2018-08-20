# Condition

- [Condition (from oracle doc)](https://docs.oracle.com/javase/7/docs/api/java/util/concurrent/locks/Condition.html)

Condition factors out the Object monitor methods (wait, notify and notifyAll) into distinct objects to give the effect of having multiple wait-sets per object, by combining them with the use of arbitrary Lock implementations. Where a Lock replaces the use of synchronized methods and statements, a Condition replaces the use of the Object monitor methods.

`Condition` 类提供了类似`Object`类中的`wait`, `notify` and `notifyAll`方法，用来替换Object类，配合`Lock`类实现线程之间的通信