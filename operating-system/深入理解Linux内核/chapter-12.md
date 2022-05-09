# 第12章 虚拟文件系统

- VFS Virtual Filesystem Switch
- 磁盘文件系统
- 网络文件系统
- 特殊文件系统
- Ext2 Ext3
- 通用文件模型 common file model
- 超级块对象 superblock object
- 索引节点对象 inode oject
- 文件对象 file object
- 目录项对象 dentry object
- 目录项高速缓存(dentry cache ) 磁盘高速缓存(disk cache )

> 图12-2:进程与VFS对象之间的交互

![深入理解Linux内核-12-2.drawio.svg](./images/深入理解Linux内核-12-2.drawio.svg)

## VSF 数据结构

- 超级块对象 super_block
- 文件对象 
- 目录项对象

### 文件对象

文件对象描述进程怎样与一个打开的文件进行交互。文件对象是在文件被打开时创建的，由一个file结构组成，其中包含的字段如表12-4所示。
注意，文件对象在磁盘上没有对应的映像，因此file结构中没有设置“脏“字段来表示文件对象是否已被修改。