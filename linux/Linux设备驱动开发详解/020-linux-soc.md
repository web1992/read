# 第20章 Linux芯片级移植及底层驱动

## P1522

- P1522
- drivers/pinctrl
- timer_tick
- 使能NO_HZ（即无节拍，或者说动态节拍）和HIGH_RES_TIMERS
- clock_event_device和clocksource
- nanosleep
- 中断控制器驱动
- local_irq_disable local_irq_enable
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 
- 

## ARM Linux底层驱动的组成和现状

为了让Linux在一个全新的ARM SoC上运行，需要
提供大量的底层支撑，如定时器节拍、中断控制器、
SMP启动、CPU热插拔以及底层的GPIO、时钟、pinctrl
和DMA硬件的封装等。定时器节拍、中断控制器、SMP
启动和CPU热插拔这几部分相对来说没有像早期GPIO、
时钟、pinctrl和DMA的实现那么杂乱，基本上有个固
定的套路。

定时器节拍为Linux基于时间片的调度机制
以及内核和用户空间的定时器提供支撑，中断控制器
的驱动则使得Linux内核的工程师可以直接调用
local_irq_disable（）、disable_irq（）等通用的
中断API，而SMP启动支持则用于让SoC内部的多个CPU
核都投入运行，CPU热插拔则运行运行时挂载或拔除
CPU。这些工作，在Linux 3.0之后的内核中，Linux社
区对比逐步进行了良好的层次划分和架构设计。

在GPIO、时钟、pinctrl和DMA驱动方面，在Linux
2.6时代，内核已或多或少有GPIO、时钟等底层驱动的
架构，但是核心层的代码太薄弱，各SoC在这些基础设
施实现方面存在巨大差异，而且每个SoC仍然需要实现
大量的代码。pinctrl和DMA则最为混乱，几乎各家公
司都定义了自己独特的实现和API。

社区必须改变这种局面，于是Linux社区在2011年
后进行了如下工作，这些工作在目前的Linux内核中基
本准备就绪：
·STEricsson公司的工程师Linus Walleij提供了
新的pinctrl驱动架构，内核中新增加一个
drivers/pinctrl目录，支撑SoC上的引脚复用，各个
SoC的实现代码统一放入该目录。

·TI公司的工程师Mike Turquette提供了通过时
钟框架，让具体SoC实现clk_ops（）成员函数，并通
过clk_register（）、clk_register_clkdev（）注册
时钟源以及源与设备的对应关系，具体的时钟驱动都
统一迁移到drivers/clk目录中。

·建议各SoC统一采用dmaengine架构实现DMA驱
动，该架构提供了通用的DMA通道API，如
dmaengine_prep_slave_single（）、
dmaengine_submit（）等，要求SoC实现dma_device的
成员函数，实现代码统一放入drivers/dma目录中。

·在GPIO方面，drivers/gpio下的gpiolib已能与
新的pinctrl完美共存，实现引脚的GPIO和其他功能之
间的复用，具体的SoC只需实现通用的gpio_chip结构
体的成员函数。


经过以上工作，基本上就把芯片底层基础架构方
面的驱动架构统一了，实现方法也统一了。另外，目
前GPIO、时钟、pinmux等都能良好地进行设备树的映
射处理，譬如我们可以方便地在.dts中定义一个设备
要的时钟、pinmux引脚以及GPIO。
除了上述基础设施以外，在将Linux移植入新的
SoC过程中，工程师常常强烈依赖于早期的printk功
能，内核则提供了相关的DEBUG_LL和EARLY_PRINTK支
持，只需要SoC提供商实现少量的回调函数或宏。

## 无节拍方案

当前Linux多采用无节拍方案，并支持高精度定时
器，内核的配置一般会使能NO_HZ（即无节拍，或者说
动态节拍）和HIGH_RES_TIMERS。要强调的是无节拍并
不是说系统中没有时钟节拍，而是说这个节拍不再像
以前那样周期性地产生。无节拍意味着，根据系统的
运行情况，以事件驱动的方式动态决定下一个节拍在
何时发生。

在当前的Linux系统中，SoC底层的定时器被实现
为一个clock_event_device和clocksource形式的驱
动。在clock_event_device结构体中，实现其
set_mode（）和set_next_event（）成员函数；在
clocksource结构体中，主要实现read（）成员函数。
而在定时器中断服务程序中，不再调用
timer_tick（），而是调用clock_event_device的
event_handler（）成员函数

## xxx_timer_interrupt

```c
static irqreturn_t xxx_timer_interrupt(int irq, void *dev_id)
{
    struct clock_event_device *ce = dev_id;
    …
    ce->event_handler(ce);

    return IRQ_HANDLED;
}

/* read 64-bit timer counter */
static cycle_t xxx_timer_read(struct clocksource *cs)
{
    u64 cycles;

    /* read the 64-bit timer counter */
    cycles = readl_relaxed(xxx_timer_base + LATCHED_HI);
    cycles = (cycles << 32) | readl_relaxed(xxx_timer_base + LATCHED_LO);

    return cycles;
}

static int xxx_timer_set_next_event(unsigned long delta, struct clock_event_device *ce)
{
    unsigned long now, next;
    now = readl_relaxed(xxx_timer_base + LATCHED_LO);
    next = now + delta;
    writel_relaxed(next, xxx_timer_base + SIRFSOC_TIMER_MATCH_0);
    ...
}

static void xxx_timer_set_mode(enum clock_event_mode mode, struct clock_event_device *ce)
{
    switch (mode) {
    case CLOCK_EVT_MODE_PERIODIC:
        …
        break;
    case CLOCK_EVT_MODE_ONESHOT:
        …
        break;
    case CLOCK_EVT_MODE_SHUTDOWN:
        …
        break;
    case CLOCK_EVT_MODE_UNUSED:
    case CLOCK_EVT_MODE_RESUME:
        break;
    }
}

static struct clock_event_device xxx_clockevent = {
    .name = "xxx_clockevent",
    .rating = 200,
    .features = CLOCK_EVT_FEAT_ONESHOT,
    .set_mode = xxx_timer_set_mode,
    .set_next_event = xxx_timer_set_next_event,
};

static struct clocksource xxx_clocksource = {
    .name = "xxx_clocksource",
    .rating = 200,
    .mask = CLOCKSOURCE_MASK(64),
    .flags = CLOCK_SOURCE_IS_CONTINUOUS,
    .read = xxx_timer_read,
    .suspend = xxx_clocksource_suspend,
    .resume = xxx_clocksource_resume,
};

static struct irqaction xxx_timer_irq = {
    .name = "xxx_tick",
    .flags = IRQF_TIMER,
    .irq = 0,
    .handler = xxx_timer_interrupt,
    .dev_id = &xxx_clockevent,
};

static void __init xxx_clockevent_init(void)
{
    clockevents_calc_mult_shift(&xxx_clockevent, CLOCK_TICK_RATE, 60);

    xxx_clockevent.max_delta_ns = clockevent_delta2ns(-2, &xxx_clockevent);
    xxx_clockevent.min_delta_ns = clockevent_delta2ns(2, &xxx_clockevent);

    xxx_clockevent.cpumask = cpumask_of(0);
    clockevents_register_device(&xxx_clockevent);
}

/* initialize the kernel jiffy timer source */
static void __init xxx_timer_init(void)
{
    …
    BUG_ON(clocksource_register_hz(&xxx_clocksource, CLOCK_TICK_RATE));
    BUG_ON(setup_irq(xxx_timer_irq.irq, &xxx_timer_irq));
    xxx_clockevent_init();
}

struct sys_timer xxx_timer = {
    .init = xxx_timer_init,
};
```
