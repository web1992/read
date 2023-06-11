# 第 18 章　预测与调度

- HotSpotVM 会利用平均值和标准差来预测未来的暂停时间
- 均值、方差和标准差
- 衰减均值decaying average
- 方差
- 标准差表示偏差的幅度
- 衰减方差（decaying variance）
- 衰减均值
- TruncatedSeq


## 并发标记的调度

```c++
// share/vm/gc_implementation/g1/concurrentMarkThread.cpp
93: void ConcurrentMarkThread::run() {
152:             double now = os::elapsedTime();
153:             double remark_prediction_ms =             g1_policy->predict_remark_time_ms()
154:             jlong sleep_time_ms =                     mmu_tracker->when_ms(now, remark_prediction_ms);
155:             os::sleep(current_thread, sleep_time_ms, false);                 /* 最终标记阶段的执行 */
165:             CMCheckpointRootsFinalClosure final_cl(_cm);
166:             sprintf(verbose_str, "GC remark");
167:             VM_CGC_Operation op(&final_cl, verbose_str);
168:             VMThread::execute(&op);
```

第 152 行的os::elapsedTime()静态成员函数会返回 HotSpotVM 启动后所经过的时间。

第 153 行的predict_remark_time_ms()会获取下次执行的最终标记阶段所消耗的时间的预测值。这个值会被传递给when_ms()成员函数。when_ms()使用算法篇 4.4 节中讲解的方法返回距离合适的暂停时机还有多长时间。接着，这个值被传递给第 155 行的os::sleep()函数，让并发标记线程在合适的暂停时机到来之前暂停执行。

并发标记中的其他暂停处理也是使用上面这样的方法来决定执行时机的。

