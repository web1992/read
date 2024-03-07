# 第1章 CSS和文档

- 元素
    - 置换元素和非置换元素
    - img 置换元素
    - 段落、标题、单元格、列表，以及 HTML 中其他几乎所有元素都是非置换元素
- 块级元素
- 行内元素
- display
- link 标签
- @import 指令
- link
- style
- 媒体描述符
- 行内样式
- 厂商前缀
- 媒体查询
- 媒体类型
- 媒体描述符
- 特性查询 @supports
- 

## 块级元素

块级元素(默认)生成一个填满父级元素内容区域的框,旁边不能有其他元素。也就是说，块级元素在元素框的前后都“断行”。HTML中最常见的块级元素是p和div。置换元素可以是块级元素，但往往不是。

列表项目是一种特殊的块级元素，它的表现与其他块级元素没有区别，此外还会在元素框旁生成一个记号(无序列表通常是圆点，有序列表通常是数字)。除了多出的这个记号以外，列表项目与其他块级元素之间没有任何区别。

## 行内元素
行内元素在一行文本内生成元素框，不打断所在的行。HTML中最常见的行内元素是 a。此外还有strong和em。这类元素不在自身所在元素框的前后“断行”，因此可以出现在另一个元素的内容中，且不影响所在的元素。


## display

```css
p {display: inline;}
em {display: block;}
```

## link 标签


```html
<link rel="stylesheet" type="text/css" href="sheet1.css" media="all">
```


## import

```html
<style type="text/css">
@import url(styles.css);/* @import 放在开头*/
h1 {color: gray;}
</style>
```

## 媒体查询

媒体查询可以在下述几个地方使用，
- link 元素的 media 属性。
- style 元素的 media 属性。
- @import 声明的媒体描述符部分
- @media 声明的媒体描述符部分。

媒体查询可以是简单的媒体类型，也可以是复杂的媒体类型和特性的组合。

## 媒体类型

- al1
用于所有展示媒体。
- print
为有视力的用户打印文档时使用，也在预览打印效果时使用。
- screen
在屏幕媒体(如桌面电脑的显示器)上展示文档时使用。在桌面计算机上运行的所有Web浏览器都是屏幕媒体用户代理。

## 媒体描述符

```
<link href="print-color.css"type="text/cssmedia="print and(color)" rel="stylesheet">
@import url(print-color.css)print and(color);
```