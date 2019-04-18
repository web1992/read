# Transporter

`Transporter` 是 `dubbo` 中 `TCP` 通信的抽象，支持 `SPI`

## interface

```java
@SPI("netty")
public interface Transporter {

    /**
     * Bind a server.
     *
     * @param url     server url
     * @param handler
     * @return server
     * @throws RemotingException
     * @see org.apache.dubbo.remoting.Transporters#bind(URL, ChannelHandler...)
     */
    @Adaptive({Constants.SERVER_KEY, Constants.TRANSPORTER_KEY})
    Server bind(URL url, ChannelHandler handler) throws RemotingException;

    /**
     * Connect to a server.
     *
     * @param url     server url
     * @param handler
     * @return client
     * @throws RemotingException
     * @see org.apache.dubbo.remoting.Transporters#connect(URL, ChannelHandler...)
     */
    @Adaptive({Constants.CLIENT_KEY, Constants.TRANSPORTER_KEY})
    Client connect(URL url, ChannelHandler handler) throws RemotingException;

}
```

## NettyTransporter

```java
public class NettyTransporter implements Transporter {

    public static final String NAME = "netty";

    @Override
    public Server bind(URL url, ChannelHandler listener) throws RemotingException {
        return new NettyServer(url, listener);
    }

    @Override
    public Client connect(URL url, ChannelHandler listener) throws RemotingException {
        return new NettyClient(url, listener);
    }

}
```

## Exchanger

```java
public class HeaderExchanger implements Exchanger {

    public static final String NAME = "header";

    @Override
    public ExchangeClient connect(URL url, ExchangeHandler handler) throws RemotingException {
        return new HeaderExchangeClient(Transporters.connect(url, new DecodeHandler(new HeaderExchangeHandler(handler))), true);
    }

    @Override
    public ExchangeServer bind(URL url, ExchangeHandler handler) throws RemotingException {
        return new HeaderExchangeServer(Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler))));
    }

}
```

在 [dubbo-init](dubbo-init.md#summary) 我们画了下面的图，现在加 `Transporter`

```txt
    ---------------customer----------------                 ------------------------provider------------------
    |                                     |                 |                                                |
    |                                     |                 |                                                |
    |                                     |                 |                                                |
  bean  -> proxy -> Invoker -> ExchangeClient  -> TCP -> ExchangeServer -> Exporter -> Invoker -> proxy ->  bean
```

```txt
    ---------------customer-----------------------------                     ------------------------provider------------------------------
    |                                                  |                     |                                                            |
    |                                                  |                     |                                                            |
    |                                                  |                     |                                                            |
  bean  -> proxy -> Invoker -> ExchangeClient -> Transporter -> TCP -> Transporter -> ExchangeServer -> Exporter -> Invoker -> proxy ->  bean
```