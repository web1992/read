# 第 14 章　GC 线程（并行篇）

- AbstractWorkGang：工作线程集合
- AbstractGangTask：让工作线程执行的任务
- GangWorker：执行指定任务的工作线程

## GangWorker

![GangWorker.drawio.svg](./images/GangWorker.drawio.svg)

## 并行 GC 的执行示例

```c++
1: /* ① 准备工人 */
2: workers = new FlexibleWorkGang("Parallel GC Threads", 8, true, false);
3: workers->initialize_workers();
4:
5: /* ② 创建任务 */
6: CMConcurrentMarkingTask marking_task(cm, cmt);
7:
8: /* ③ 并行执行任务 */
9: workers->run_task(&marking_task);
```

