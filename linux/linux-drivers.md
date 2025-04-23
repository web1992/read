# drivers

内核一般要做到drivers与arch的软件架构分离，
驱动中不包含板级信息，让驱动跨平台。同时内核的
通用部分（如kernel、fs、ipc、net等）则与具体的
硬件（arch和drivers）剥离。
