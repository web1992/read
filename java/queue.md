# Queue

- [Queue (from oracle docs)](https://docs.oracle.com/javase/tutorial/collections/implementations/queue.html)

![Queue](images/queue.png)

## BlockingQueue

||Throws exception|Special value|Blocks|Times out
------|----------|-------------|------|----------
Insert|add(e)|offer(e)|put(e)|offer(e, time, unit)
Remove|remove()|poll()|take()|poll(time, unit)
Examine(检查)|element()|peek()|not applicable|not applicable

## ArrayBlockingQueue

![ArrayBlockingQueue](./images/ArrayBlockingQueue.png)