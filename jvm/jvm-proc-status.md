# proc status

JVM native memory 跟踪

- -XX:+UnlockDiagnosticVMOptions -XX:+PrintNMTStatistics
- -XX:NativeMemoryTracking=[off | summary | detail]
- jcmd 23633 VM.native_memory summary scale=MB

```sh
## cat /proc/2936/status
Name:   java
Umask:  0002
State:  S (sleeping)
Tgid:   2936
Ngid:   0
Pid:    2936
PPid:   1
TracerPid:      0
Uid:    1999    1999    1999    1999
Gid:    1999    1999    1999    1999
FDSize: 1024
Groups: 1999
VmPeak: 10125728 kB
VmSize:  9994656 kB
VmLck:         0 kB
VmPin:         0 kB
VmHWM:   3996064 kB
VmRSS:   3988836 kB
RssAnon:         3981328 kB
RssFile:            7508 kB
RssShmem:              0 kB
VmData:  9806124 kB
VmStk:       132 kB
VmExe:         4 kB
VmLib:     18216 kB
VmPTE:     11400 kB
VmSwap:        0 kB
Threads:        735
SigQ:   0/30818
SigPnd: 0000000000000000
ShdPnd: 0000000000000000
SigBlk: 0000000000000000
SigIgn: 0000000000000003
SigCgt: 2000000181005ccc
CapInh: 0000000000000000
CapPrm: 0000000000000000
CapEff: 0000000000000000
CapBnd: 0000001fffffffff
CapAmb: 0000000000000000
NoNewPrivs:     0
Seccomp:        0
Speculation_Store_Bypass:       vulnerable
Cpus_allowed:   f
Cpus_allowed_list:      0-3
Mems_allowed:   00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000001
Mems_allowed_list:      0
voluntary_ctxt_switches:        15
nonvoluntary_ctxt_switches:     6
```