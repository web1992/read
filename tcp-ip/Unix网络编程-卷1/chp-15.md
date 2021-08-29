# Unix 域协议

```c
struct sockaddr_un
{
    uint8_t sun_len;           // 有些实现中可能没有这个成员
    sa_family_t sun_family;    // AF_LOCAL
    char sun_path[104];        // null-terminated pathname. 有些实现中该值可能为108
};
```