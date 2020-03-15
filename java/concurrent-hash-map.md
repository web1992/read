# ConcurrentHashMap

`ConcurrentHashMap` 是为了并发而生的容器，那么底层是通过哪些手段来保证并发访问中出现的问题的呢？

比如：并发的`修改`，`访问`，`扩容` 同时保证较高的性能。

- [ConcurrentHashMap](#concurrenthashmap)
  - [Api 操作](#api-%e6%93%8d%e4%bd%9c)
    - [Put](#put)
    - [Get](#get)
    - [Remove](#remove)
    - [Transfer](#transfer)
  - [数据结构](#%e6%95%b0%e6%8d%ae%e7%bb%93%e6%9e%84)
    - [Node](#node)
    - [TreeNode](#treenode)
    - [TreeBin](#treebin)
    - [ForwardingNode](#forwardingnode)

## Api 操作

### Put

### Get

### Remove

### Transfer

## 数据结构

### Node

### TreeNode

### TreeBin

### ForwardingNode
