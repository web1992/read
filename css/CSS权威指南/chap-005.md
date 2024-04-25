# 第5章 字体

- 衬线字体
- 字体族使用 font-family 属性声明
- @font-face 
- font-weight
- font-size em-盒子
- line-height
- 绝对大小 xx-small、x-small、small、medium、large、x-large，xx-large
- 相对大小 larger和smaller 它们根据父元素的字号增大或减小一定比例
- 百分数和 em
- 百分数始终根据继承自父元素的字号计算
- CSS 还把长度单位 em 定义为等效于百分数,对字号而言,1em与100%的效果相同。
- font-size-adjust
- font-style 属性的作用十分简单:在 normal(常规)、italic(斜体)和 oblique(倾斜体)之间做出选择。
- font-stretch
- font-kerning
- 字体变形
- font-variant

## 通用字体族

鉴于此，笔者强烈建议始终在 font-family 规则中指定通用字体族。这样做相当于提供一种后备机制,在用户代理找不到匹配的字体时,选择一个字体代替。

```
h1 (font-family: Arial, sans-serif;}
h2 {font-family: Charcoal， sans-serif;}
```

## @font-face 

假设你想使用的字体没有广泛安装，而是个十分特别的字体，借助 @font-face 的魔力，你可以定义一个专门的字体族名称，对应于服务器上的一个字体文件。用户代理将下载那个文件，使用它渲染页面中的文本，就好像用户的设备中安装了那个字体一样。

```css
@font-face {
font-family:"SwitzeraADF"; /* 描述符 */
src: url("SwitzeraADF-Regular.otf");
}

h1 {font-family: SwitzeraADF，Helvetica，sans-serif;} /* 属性*/
```

注意，font-family 描述符的值和 font-family 属性中出现的那个字体族名是一样的如果不一样，h1 规则将忽略 font-family 属性值中列出的第一个字体族名称，解析后一个。只要成功下载了字体文件，而且文件的格式是用户代理支持的，那个字体就会像其他字体一样用于渲染文本。
