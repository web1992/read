# CHAPTER 11

## Idle connections and timeouts

- `IdleStateHandler`
- `ReadTimeoutHandler`
- `WriteTimeoutHandler`

## Delimited protocols

Delimited message protocols use defined characters to mark the beginning or end of a
message or message segment, often called a frame. This is true of many protocols for-
mally defined by  RFC documents, such as  SMTP ,  POP3 ,  IMAP , and Telnet. 5 And, of
course, private organizations often have their own proprietary formats.

## Length-based protocols

## Serializing data

The JDK provides `ObjectOutputStream` and `ObjectInputStream` for serializing and deserializing primitive data types and graphs of POJOs over the network. The API isn’t
complex and can be applied to any object that implements `java.io.Serializable`. But
it’s also not terribly efficient. In this section we’ll see what Netty has to offer.

## JDK serialization

- CompatibleObjectDecoder(jdk)
- CompatibleObjectEncoder(jdk)

- ObjectDecoder(netty)
- ObjectEncoder(netty)

## Serialization with JBoss Marshalling

JBoss Marshalling codecs

Name | Description
-----|-------------
CompatibleMarshallingDecoder CompatibleMarshallingEncoder | For compatibility with peers that use JDK serialization.
MarshallingDecoder MarshallingEncoder | For use with peers that use JBoss Marshalling. These classes must be used together.

## Serialization via Protocol Buffers

The last of Netty’s solutions for serialization is a codec that utilizes Protocol Buffers, 8 a
data interchange format developed by Google and now open source. The code can be
found at https://github.com/google/protobuf.
Protocol Buffers encodes and decodes structured data in a way that’s compact and
efficient. It has bindings for many programming languages, making it a good fit for
cross-language projects