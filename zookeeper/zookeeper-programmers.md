# Zookeeper Programmers

- [Zookeeper Programmers](#zookeeper-programmers)
  - [The ZooKeeper Data Model](#the-zookeeper-data-model)
  - [ZooKeeper Watches](#zookeeper-watches)
  - [Pluggable ZooKeeper authentication](#pluggable-zookeeper-authentication)
  - [Consistency Guarantees](#consistency-guarantees)
  - [Building Blocks: A Guide to ZooKeeper Operations](#building-blocks-a-guide-to-zookeeper-operations)

ZooKeeper Programmer's Guide

Developing Distributed Applications that use ZooKeeper

You can see origin document at here [Zookeeper Programmers](https://zookeeper.apache.org/doc/r3.5.3-beta/zookeeperProgrammers.html)

## The ZooKeeper Data Model

[Link](https://zookeeper.apache.org/doc/r3.5.3-beta/zookeeperProgrammers.html#ch_zkDataModel)

- ZNodes
- Watches
- Data Access
- Ephemeral Nodes
- Sequence Nodes -- Unique Naming

## ZooKeeper Watches

- One-time trigger
- Sent to the client
- The data for which the watch was set

## Pluggable ZooKeeper authentication

```java
public interface AuthenticationProvider {
    String getScheme();
    KeeperException.Code handleAuthentication(ServerCnxn cnxn, byte authData[]);
    boolean isValid(String id);
    boolean matches(String id, String aclExpr);
    boolean isAuthenticated();
}
```

## Consistency Guarantees

## Building Blocks: A Guide to ZooKeeper Operations

[Link](https://zookeeper.apache.org/doc/r3.5.3-beta/zookeeperProgrammers.html#sc_connectingToZk)

Gotchas: Common Problems and Troubleshooting

So now you know ZooKeeper. It's fast, simple, your application works, but wait ... something's wrong. Here are some pitfalls that ZooKeeper users fall into:

- If you are using watches, you must look for the connected watch event. When a ZooKeeper client disconnects from a server, you will not receive notification of changes until reconnected. If you are watching for a znode to come into existence, you will miss the event if the znode is created and deleted while you are disconnected.

- You must test ZooKeeper server failures. The ZooKeeper service can survive failures as long as a majority of servers are active. The question to ask is: can your application handle it? In the real world a client's connection to ZooKeeper can break. (ZooKeeper server failures and network partitions are common reasons for connection loss.) The ZooKeeper client library takes care of recovering your connection and letting you know what happened, but you must make sure that you recover your state and any outstanding requests that failed. Find out if you got it right in the test lab, not in production - test with a ZooKeeper service made up of a several of servers and subject them to reboots.

- The list of ZooKeeper servers used by the client must match the list of ZooKeeper servers that each ZooKeeper server has. Things can work, although not optimally, if the client list is a subset of the real list of ZooKeeper servers, but not if the client lists ZooKeeper servers not in the ZooKeeper cluster.

- Be careful where you put that transaction log. The most performance-critical part of ZooKeeper is the transaction log. ZooKeeper must sync transactions to media before it returns a response. A dedicated transaction log device is key to consistent good performance. Putting the log on a busy device will adversely effect performance. If you only have one storage device, put trace files on NFS and increase the snapshotCount; it doesn't eliminate the problem, but it can mitigate it.

- Set your Java max heap size correctly. It is very important to avoid swapping. Going to disk unnecessarily will almost certainly degrade your performance unacceptably. Remember, in ZooKeeper, everything is ordered, so if one request hits the disk, all other queued requests hit the disk.

- To avoid swapping, try to set the heapsize to the amount of physical memory you have, minus the amount needed by the OS and cache. The best way to determine an optimal heap size for your configurations is to run load tests. If for some reason you can't, be conservative in your estimates and choose a number well below the limit that would cause your machine to swap. For example, on a 4G machine, a 3G heap is a conservative estimate to start with.

[Barrier and Queue Tutorial](https://cwiki.apache.org/confluence/display/ZOOKEEPER/Tutorial)

[ZooKeeper - A Reliable, Scalable Distributed Coordination SystemAn article by Todd Hoff (07/15/2008)](https://cwiki.apache.org/confluence/display/ZOOKEEPER/ZooKeeperArticles)

[ZooKeeper Recipes and Solutions](https://zookeeper.apache.org/doc/r3.5.3-beta/recipes.html)

Pseudo-level discussion of the implementation of various synchronization solutions with ZooKeeper: Event Handles, Queues, Locks, and Two-phase Commits
