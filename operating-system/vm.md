# VM

- Host 物理主机
- Guest 宿主机
- 基于内核的虚拟机 (Kernel based Virtual Machine, KVM)

## 虚拟化的三个基本条件

- 等价性
- 资源限制
- 高效性

## 陷入模拟（Trap-and-Emulate）模型

陷入模型的核心思想是：将 Guest 运行的指令进行分类，一类是安全的指令，也就是说这些指令可以让 Host 的 CPU 正常执行而不会产生任何副作用，例如普通的数学运算或者逻辑运算，或者普通的控制流跳转指令等；另一类则是一些“不安全”的指令，又称为“Trap”指令，也就是说，这些指令需要经过 VMM 进行模拟执行，例如中断、IO 等特权指令等。

在这个例子中，Geust 退回 VMM 的操作就是 Trap，VMM 模拟 CPU 的动作去调用 Guest 的中断服务程序就是 Emulate。

## CPU 的执行模式

- root mode 和 non-root mode 这两种模式都支持 ring 0 ~ ring 3 三种特权级别
- VM Exit
- VM Entry

现代的 X86 芯片提供了 VMX 指令来支持虚拟化，并且在 CPU 的执行模式上提供了两种模式：root mode 和 non-root mode，这两种模式都支持 ring 0 ~ ring 3 三种特权级别。VMM 会运行在 root mode 下，而 Guest 操作系统则运行在 non-root mode 下。所以，对于 Guest 的系统来讲，它也和物理机一样，可以让 kernel 运行在 ring 0 的内核态，让用户程序运行在 ring 3 的用户态， 只不过整个 Guest 都是运行在 non-root 模式下。

有了 VMX 硬件的支持，Trap-and-Emulate 就很好实现了。Guest 可以在 root 模式下正常执行指令，就如同在执行物理机的指令一样。当遇到“不安全”指令时，例如 I/O 或者中断等操作，就会触发 CPU 的 trap 动作，使得 CPU 从 non-root 模式退出到 root 模式，之后便交由 VMM 进行接管，负责对 Guest 请求的敏感指令进行模拟执行。这个过程称为 VM Exit。

而处于 root 模式下的 VMM，在一开始准备好 Guest 的相关环境，准备进入 Guest 时，或者在 VM Exit 之后执行完 Trap 指令的模拟准备，再次进入 Guest 的时候，可以继续通过 VMX 提供的相关指令 VMLAUNCH 以及 VMResume，来切换到 non-root 模式中由 Guest 继续执行。 这个过程也被称为 VM Entry。

- Host Physical Address, HPA
- Host Virtual Address，HVA
- Guest Physical Address,GPA
- 影子页表 (Shadow page table)
- 扩展页表 (Extended Page Table, EPT)