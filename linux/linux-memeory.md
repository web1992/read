# Reserved Memory Committed Memory

In Linux, the concepts of reserved memory and committed memory are related to the memory management system. Let's understand each term:

1. Reserved Memory: Reserved memory refers to the memory space that has been allocated by the kernel but might not be currently in use. It is essentially a portion of the virtual memory address space that has been reserved for a specific purpose but might not have physical memory backing it at all times. The kernel reserves this memory to ensure that it is available when needed, even though it might not be actively used at the moment.

2. Committed Memory: Committed memory, also known as virtual memory or address space, is the total amount of memory that processes have allocated or reserved for their use. It represents the sum of all memory allocations made by running processes in the system. Committed memory includes both the physical memory in use and any additional memory that has been paged out to disk.

The committed memory includes the memory regions that are currently in use, as well as the reserved memory regions. However, it's important to note that the reserved memory might not be immediately backed by physical memory, whereas the memory actively in use by processes is backed by physical memory.

To view the reserved and committed memory in Linux, you can use various tools such as `top`, `htop`, `free`, or the `proc` file system. These tools provide information about the system's memory usage, including the total memory, used memory, free memory, and various other details.

Keep in mind that the exact commands or options to view memory usage might vary depending on the Linux distribution and version you are using. It's recommended to refer to the documentation or help pages specific to your system for accurate information.
