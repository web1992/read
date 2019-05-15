# Decorator pattern

装饰器设计模式，23种设计模式之一

想要理解这个设计模式，可参照 [wikipedia](https://en.wikipedia.org/wiki/Decorator_pattern) 的解释

下面只是自己的理解，

## 解决的问题

1. 可以动态（运行时）的修改类的职责
2. 可以灵活的替代子类继承的一种设计模式

装饰器模式的优点就是在运行时，动态的包装类，增强类的功能，而继承则做不到。

## demo

```java
/**
 * desc: 一个牛逼的 枪，基于 装饰器模式
 * <p>
 *
 * @author web1992
 * <p>
 */
public class DecoratorPatternDemo {
    public static void main(String[] args) {

        Gun customerGun = new CustomerGun();
        customerGun = new AKGun(customerGun);
        customerGun = new M4Gun(customerGun);
        customerGun = new GatlinGun(customerGun);
        customerGun.fire();

        System.out.println("--------------------------");
        // 动态性，换个顺序
        // 去掉 GatlinGun
        Gun customerGun1 = new CustomerGun();
        customerGun1 = new M4Gun(customerGun1);
        customerGun1 = new AKGun(customerGun1);
        customerGun1.fire();

    }
}


/**
 * 枪接口
 */
interface Gun {
    void fire();
}

abstract class AbstractGun implements Gun {
    @Override
    public void fire() {
        System.out.println("AbstractGun# prepare fire ...");
    }
}


class AKGun implements Gun {

    private Gun gun;

    public AKGun(Gun gun) {
        this.gun = gun;
    }

    @Override
    public void fire() {
        gun.fire();
        System.out.println("AKGun# ta ta tu tu ...");
    }
}

class M4Gun implements Gun {

    private Gun gun;

    public M4Gun(Gun gun) {
        this.gun = gun;
    }

    @Override
    public void fire() {
        gun.fire();
        System.out.println("M4Gun# ta ta tu tu ...");
    }
}


class GatlinGun extends AbstractGun implements Gun {
    private Gun gun;

    public GatlinGun(Gun gun) {
        this.gun = gun;
    }

    @Override
    public void fire() {
        super.fire();
        gun.fire();
        System.out.println("GatlinGun# ta ta tu tu tu ...");
    }
}

class CustomerGun implements Gun {

    @Override
    public void fire() {
        System.out.println("CustomerGun# ta ta ta ta ...");
    }
}
```

## 参考

- [Decorator pattern](https://en.wikipedia.org/wiki/Decorator_pattern)