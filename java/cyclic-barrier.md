# CyclicBarrier

## docs

A synchronization aid that allows a set of threads to all wait for
each other to reach a common barrier point. `CyclicBarriers` are
useful in programs involving a fixed sized party of threads that
must occasionally wait for each other. The barrier is called
`cyclic` because it can be re-used after the waiting threads
are released.
