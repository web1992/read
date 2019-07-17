# Task Execution and Scheduling

- 1 [introduction](#introduction)
- 2 [the-spring-taskexecutor-abstractionsimpleasynctaskexecutor](#the-spring-taskexecutor-abstractionsimpleasynctaskexecutor)
- 3 [taskexecutor-types](#taskexecutor-types)
- 4 [using-a-taskexecutor](#using-a-taskexecutor)
- 5 [the-spring-taskscheduler-abstraction](#the-spring-taskscheduler-abstraction)
- 6 [trigger-interface](#trigger-interface)
- 7 [trigger-implementations](#trigger-implementations)
- 8 [using-the-quartz-scheduler](#using-the-quartz-scheduler)

## Introduction

`TaskExecutor`
`TaskScheduler`

## The Spring TaskExecutor abstractionSimpleAsyncTaskExecutor

`SyncTaskExecutor`
`ConcurrentTaskExecutor`
`ThreadPoolTaskExecuto`
`ConcurrentTaskExecutor`
`SimpleThreadPoolTaskExecutor`
`ThreadPoolTaskExecutor`
`WorkManagerTaskExecutor`

Spring’s TaskExecutor interface is identical to the java.util.concurrent.Executor interface. In fact, originally, its primary reason for existence was to abstract away the need for Java 5 when using thread pools. The interface has a single method execute(Runnable task) that accepts a task for execution based on the semantics and configuration of the thread pool.

## TaskExecutor types

`SimpleAsyncTaskExecutor`
`ThreadPoolTaskExecutor`
`SyncTaskExecutor`
`ConcurrentTaskExecutor`
`ThreadPoolTaskExecutor`
`ConcurrentTaskExecutor`
`SimpleThreadPoolTaskExecutor`
`ThreadPoolTaskExecutor`
`WorkManagerTaskExecutor`

## Using a TaskExecutor

```java
import org.springframework.core.task.TaskExecutor;

public class TaskExecutorExample {

    private class MessagePrinterTask implements Runnable {

        private String message;

        public MessagePrinterTask(String message) {
            this.message = message;
        }

        public void run() {
            System.out.println(message);
        }

    }

    private TaskExecutor taskExecutor;

    public TaskExecutorExample(TaskExecutor taskExecutor) {
        this.taskExecutor = taskExecutor;
    }

    public void printMessages() {
        for(int i = 0; i < 25; i++) {
            taskExecutor.execute(new MessagePrinterTask("Message" + i));
        }
    }

}
```

To configure the rules that the TaskExecutor will use, simple bean properties have been exposed.

```xml
<bean id="taskExecutor" class="org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor">
    <property name="corePoolSize" value="5" />
    <property name="maxPoolSize" value="10" />
    <property name="queueCapacity" value="25" />
</bean>

<bean id="taskExecutorExample" class="TaskExecutorExample">
    <constructor-arg ref="taskExecutor" />
</bean>
```

## The Spring TaskScheduler abstraction

```java
public interface TaskScheduler {

    ScheduledFuture schedule(Runnable task, Trigger trigger);

    ScheduledFuture schedule(Runnable task, Date startTime);

    ScheduledFuture scheduleAtFixedRate(Runnable task, Date startTime, long period);

    ScheduledFuture scheduleAtFixedRate(Runnable task, long period);

    ScheduledFuture scheduleWithFixedDelay(Runnable task, Date startTime, long delay);

    ScheduledFuture scheduleWithFixedDelay(Runnable task, long delay);

}
```

## Trigger interface

`Trigger`
`TriggerContext`

```java
public interface Trigger {

    Date nextExecutionTime(TriggerContext triggerContext);

}
```

```java
public interface TriggerContext {

    Date lastScheduledExecutionTime();

    Date lastActualExecutionTime();

    Date lastCompletionTime();

}
```

## Trigger implementations

Spring provides two implementations of the Trigger interface. The most interesting one is the CronTrigger. It enables the scheduling of tasks based on cron expressions. For example, the following task is being scheduled to run 15 minutes past each hour but only during the 9-to-5 "business hours" on weekdays.

```java
scheduler.schedule(task, new CronTrigger("0 15 9-17 * * MON-FRI"));
```

## Using the Quartz Scheduler

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#scheduling-quartz)