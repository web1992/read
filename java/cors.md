# CORS

```java
    private static final String HEADER_ORGIN = "Access-Control-Allow-Origin";
    private static final String HEADER_METHOD = "Access-Control-Allow-Method";
    private static final String HEADER_METHOD_VALUE = "POST, GET, OPTIONS, PUT, DELETE, HEAD";
    private static final String HEADER_CREDENTIALS = "Access-Control-Allow-Credentials";
    private static final String HEADER_CREDENTIALS_VALUE = "true";
    private static final String HEADER_CONTROL_MAX_AGE = "Access-Control-Max-Age";
    private static final String HEADER_CONTROL_MAX_AGE_VALUE = "600";
    
    public static void setCORSHeader(HttpServletRequest request, HttpServletResponse response) {
        // 解决H5跨域问题
        String origin = request.getHeader("Origin");
        origin = origin == null ? request.getHeader("Referer") : origin;
        if (!StringUtils.isBlank(origin)) {
            response.setHeader(HEADER_ORGIN, origin);
            response.addHeader(HEADER_METHOD, HEADER_METHOD_VALUE);
            response.setHeader(HEADER_CREDENTIALS, HEADER_CREDENTIALS_VALUE);
            response.setHeader(HEADER_CONTROL_MAX_AGE, HEADER_CONTROL_MAX_AGE_VALUE);
        }
    }
```