# TCP的交互数据流

- 经受时延的确认
- Nagle算法
- 窗口大小
- 时延确认

如果连接上客户一般每次发送一个字节到服务器，被称为微小分组（tinygram）,这些小分组则会增加拥塞出现的可能。

Nagle算法，该算法要求一个TCP连接上最多只能有一个未被确认的未完成的小分组，在该分组的确
认到达之前不能发送其他的小分组。相反， TCP收集这些少量的分组，并在确认到来时以一
个分组的方式发出去。该算法的优越之处在于它是自适应的：确认到达得越快，数据也就发
送得越快。而在希望减少微小分组数目的低速广域网上，则会发送更少的分

插口API用户可以使用 `TCPNODELAY` 选项来关闭`Nagle`算法。
