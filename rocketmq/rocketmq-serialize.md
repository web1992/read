# Serialize

RocketMQ `RemotingCommand` 序列化

支持 JSON 和 `ROCKETMQ` 二种序列化方式

```java
JSON((byte) 0),
ROCKETMQ((byte) 1);
```

## 序列化的Body

```java
// RemotingCommand
private int code;
private LanguageCode language = LanguageCode.JAVA;
private int version = 0;
private int opaque = requestId.getAndIncrement();
private int flag = 0;
private String remark;
private HashMap<String, String> extFields;
```

## Decode

反序列化(解码)：`byte[]` 转化成 `RemotingCommand` 对象

```java
// RocketMQSerializable#rocketMQProtocolDecode
public static RemotingCommand rocketMQProtocolDecode(final byte[] headerArray) {
    RemotingCommand cmd = new RemotingCommand();
    ByteBuffer headerBuffer = ByteBuffer.wrap(headerArray);
    // int code(~32767)
    cmd.setCode(headerBuffer.getShort());
    // LanguageCode language
    cmd.setLanguage(LanguageCode.valueOf(headerBuffer.get()));
    // int version(~32767)
    cmd.setVersion(headerBuffer.getShort());
    // int opaque
    cmd.setOpaque(headerBuffer.getInt());
    // int flag
    cmd.setFlag(headerBuffer.getInt());
    // String remark
    int remarkLength = headerBuffer.getInt();
    if (remarkLength > 0) {
        byte[] remarkContent = new byte[remarkLength];
        headerBuffer.get(remarkContent);
        cmd.setRemark(new String(remarkContent, CHARSET_UTF8));
    }
    // HashMap<String, String> extFields
    int extFieldsLength = headerBuffer.getInt();
    if (extFieldsLength > 0) {
        byte[] extFieldsBytes = new byte[extFieldsLength];
        headerBuffer.get(extFieldsBytes);
        cmd.setExtFields(mapDeserialize(extFieldsBytes));
    }
    return cmd;
}
```

## Encode

序列化(编码)：`RemotingCommand` 转化成 `byte[]`对象

```java
 public static byte[] rocketMQProtocolEncode(RemotingCommand cmd) {
        // String remark
        byte[] remarkBytes = null;
        int remarkLen = 0;
        if (cmd.getRemark() != null && cmd.getRemark().length() > 0) {
            remarkBytes = cmd.getRemark().getBytes(CHARSET_UTF8);
            remarkLen = remarkBytes.length;
        }

        // HashMap<String, String> extFields
        byte[] extFieldsBytes = null;
        int extLen = 0;
        if (cmd.getExtFields() != null && !cmd.getExtFields().isEmpty()) {
            extFieldsBytes = mapSerialize(cmd.getExtFields());
            extLen = extFieldsBytes.length;
        }

        int totalLen = calTotalLen(remarkLen, extLen);

        ByteBuffer headerBuffer = ByteBuffer.allocate(totalLen);
        // int code(~32767)
        headerBuffer.putShort((short) cmd.getCode());
        // LanguageCode language
        headerBuffer.put(cmd.getLanguage().getCode());
        // int version(~32767)
        headerBuffer.putShort((short) cmd.getVersion());
        // int opaque
        headerBuffer.putInt(cmd.getOpaque());
        // int flag
        headerBuffer.putInt(cmd.getFlag());
        // String remark
        if (remarkBytes != null) {
            headerBuffer.putInt(remarkBytes.length);
            headerBuffer.put(remarkBytes);
        } else {
            headerBuffer.putInt(0);
        }
        // HashMap<String, String> extFields;
        if (extFieldsBytes != null) {
            headerBuffer.putInt(extFieldsBytes.length);
            headerBuffer.put(extFieldsBytes);
        } else {
            headerBuffer.putInt(0);
        }

        return headerBuffer.array();
    }
```

## CommandCustomHeader