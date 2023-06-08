# 第 13 章　线程的互斥处理


- 互斥量 mutex 
- mutex 由 mutal exclusion（互斥条件）合成而来的。
- monitor 监视器
- 条件变量（condition variable）
- Java 中提供的就是这种不带条件变量的简单的监视器。
- _cond是条件变量，_mutex是互斥量
- mutex.hpp
- Mutex 类
- Monitor 类
- MutexLocker 类