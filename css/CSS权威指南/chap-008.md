# 第8章 内边距、边框、轮廓和外边距

- 盒模型(box model)
- padding 内边距
- 元素的背景默认延伸到内边距区域
- padding: top right bottom left
- TRouBLe
- padding-top, padding-right, padding-bottom,padding-left
- 百分数值是相对父元素的宽度计算的

## box model

![box](images/box-mode.png)

## width height

width height 这两个属性有一点要注意:无法应用到行内非置换元素上。

比如说，为正常流动模式下生成行内框的超链接声明的 height 和 width，在遵守 CSS 标准的浏览器中会被忽略。假设应用的是下述规则:

```css
a:link {color:red;background:silver; height:15px; width: 60px;}
```

那么，链接在未访问的状态下将呈现为银底红字，而其高度和宽度由链接的内容决定，而不是 15 像素高、60 像素宽。但是，如果加上 display 属性，把值设为 inline-block或block，那么 height和width的值将被采用，分别设定链接内容区的高度和宽度。


## padding

```css
h2 {
    padding:14px 5em 0.1in 3ex;/*不同类型的长度值 */
}
```
