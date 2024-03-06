# 第2章 选择符

- 群组选择符
- 同时使用群组选择符和群组声明
- 类选择符和 ID 选择符
- 属性选择符
- 根据文档结构选择
- 伪类选择符
- 伪元素选择符

## 元素选择符(element selector)

```css
html {
    color: black;
}

h1 {
    color: gray;
}

h2 {
    color: silver;
}color: red;
}
```

## 群组选择符

 ```css
/* 同时使用群组选择符和群组声明 */
h2,p {
    color: gray;
    background: white;
}
 ```

 ## 类选择符和 ID 选择符


 ```css
p.warning {font-weight: bold;}
span.warning {font-style: italic;}
 ```

 ## 选择符ID

 ```css
*#first-para {font-weight: bold;}
 ```


 ## 多个类

```css
p.warning.help {background: red;}
```