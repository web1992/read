# CHAPTER 11

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