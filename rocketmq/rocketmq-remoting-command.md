# RemotingCommand

RockemtMQ 的 `Client`(Consumer,Producer) 与 `Server`(Broker) 的交互

## RequestCode

- SEND_BATCH_MESSAGE
- SEND_REPLY_MESSAGE_V2
- SEND_REPLY_MESSAGE
- PULL_MESSAGE

## CommandCustomHeader

常用的 CommandCustomHeader

| RequestCode           | Request Header              | Respone Header            | 描述               |
| --------------------- | --------------------------- | ------------------------- | ------------------ |
| SEND_REPLY_MESSAGE_V2 | SendMessageRequestHeaderV2  | SendMessageResponseHeader | 发消息的请求和响应 |
| SEND_REPLY_MESSAGE    | SendMessageRequestHeader    | SendMessageResponseHeader | 发消息的请求和响应 |
| SEND_MESSAGE          | --                          | --                        | 没有 Reply的消息   |
| PULL_MESSAGE          | PullMessageRequestHeader    | PullMessageResponseHeader | 拉消息的请求和响应 |
| --                    | EndTransactionRequestHeader | --                        | 事物结束消息       |
