# 第九章 虚拟机监控工具

- 虚拟机进程查看工具`jps`的实现
- 虚拟机配置工具`jinfo`的实现
- 堆内存转储工具`jmap`的实现
- 堆内存分析工具`jhat`的实现
- 图形化堆转储文件分析工具MAT
- 虚拟机统计信息监视工具`jstat`的实现
- Attach、HPROF、Agent、PerfData 等机制
- 线程转储工具`jstack`
- 利用`jstack`对程序进行监测和分析
- 共享内存
- 连接机制(Attach Mechanism)
- AttachProvider
- attachListener.cpp
- MonitoredVmUtil.java

## Attach

```cpp
// attachListener.cpp
static AttachOperationFunctionInfo funcs[] = {
  { "agentProperties",  get_agent_properties },
  { "datadump",         data_dump },
  { "dumpheap",         dump_heap },
  { "load",             load_agent },
  { "properties",       get_system_properties },
  { "threaddump",       thread_dump },
  { "inspectheap",      heap_inspection },
  { "setflag",          set_flag },
  { "printflag",        print_flag },
  { "jcmd",             jcmd },
  { NULL,               NULL }
};
```

