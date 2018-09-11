# Charset

## defaultCharset

```java
Charset.defaultCharset()
```

## availableCharsets

```java
Charset.availableCharsets()
```

## UTF-8&GBK

```java
public static void main(String[] args) {
        System.out.println(Charset.defaultCharset());

        // UTF-8 -> GBK
        // 你好 -> 浣犲ソ
        String hello = "你好";
        ByteBuffer buffer = ByteBuffer.wrap(hello.getBytes(Charset.forName("UTF-8")));
        CharBuffer decode = Charset.forName("GBK").decode(buffer);
        System.out.println(decode.toString());

        // GBK -> UTF-8
        // 浣犲ソ -> 你好
        String s = "浣犲ソ";
        ByteBuffer bufferGBK = ByteBuffer.wrap(s.getBytes(Charset.forName("GBK")));
        CharBuffer decodeGBK = Charset.forName("UTF-8").decode(bufferGBK);
        System.out.println(decodeGBK.toString());


    }
```