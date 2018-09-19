# CHAPTER 1

## java nio

- Using  setsockopt() you can configure  socket s so that read/write calls will return immediately if there is no data; that is, if a blocking call would haveblocked.
- You can register a set of non-blocking sockets using the system’s event notification API 2 to determine whether any of them have data ready for reading or writing.

## java nio selectors

![java nio selectors](images/java-nio-selector.png)

## Asynchronous and event-driven

What is the connection between asynchrony and scalability?

- Non-blocking network calls free us from having to wait for the completion of an operation. Fully asynchronous  I/O builds on this feature and carries it a step further: an asynchronous method returns immediately and notifies the user when it is complete, directly or at a later time.

- Selectors allow us to monitor many connections for events with many fewer threads.

## Nettry Channels

## Nettry Callbacks

## Nettry Futures

## Nettry Events and handlers

## Putting it all together