# 第9章 颜色、背景和渐变

- 前景色 color
- 这是因为前景色默认应用到边框上
- color 继承颜色
- background-color
- background-clip 裁剪背景
- background-origin
- background-repeat
- background-attachment
- background-size
## 复选框

比外注意，复选框中的勾号是黑色的。这是因为某些Web浏览器通常根据操作系统的用
户界面构建表单中的小组件。你见到的复选框和勾号其实不是 HTML 文档中的内容，而
是插入文档的用户界面小组件，就像图像一样。其实，表单输入框与图像一样，也是置
换元素。理论上，CSS 无法装饰置换元素的内容。

## background-repeat

初一看,background-repeat 的取值句法有点复杂,但其实相当简单。说到底,只有四个值:
repeat、no-repeat、space和round。另外两个值，repeat-x和repeat-y，算是其他组
合值的简写。

| 单个关键字 | 等效的关键字       |
| ---------- | ------------------ |
| repeat-x   | repeat no-repeat    |
| repeat-y   | no-repeat repeat    |
| repeat     | repeat repeat       |
| no-repeat  | no-repeat no-repeat |
| space      | space space         |
| round      | round round         |
