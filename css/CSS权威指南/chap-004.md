# 第四章 值和单位

- CSS3 定义了几个“全局”关键字，规范中的每个属性都能使用: inherit、initial 和 unset.
- URL
- 图像
- 字符串
- 标识符区分大小写
- 单位弹性值 1fr
- 数字
- 百分数
- 媒体查询 @media
- em 对应的font-size
- rem 
- ex
- ch 单位，一个字符
- 视区相关的单位
- 计算值 calc
- attr + calc
- 具名颜色
- RGB 和 RGBa 颜色
- 十六进制 RGB 值 #RRGGBB
- HSL和 HSLa 颜色
- 色谱
- transparent和 currentColor。
- 角度
- 时间和频率
- 位置 left,right,top,bottom,center

## 绝对长度单位

- 英寸 in
- 厘米 cm
- 毫米 mm
- 四分之一毫米 q
- 点 pt 点是一个标准的印刷度量单位
- 派卡 pc
- 像素 
- (pixels perinch，ppi)  

## 点 (pt)

点是一个标准的印刷度量单位，在打印机和打字机上已经使用数十年，字处理程序也使用多年了。按惯例，1 英寸有 72 点 (点是在米制系统广泛使用之前定义的)
因此,把大写字母设为 12 点的意思是文本的高度为 1/6 英寸高。例如,p {font-size:18pt;}等效于 p{font-size: 0.25in;}。


## 像素 (px)

像素是屏幕上的小点，不过 CSS 定义的像素较为抽象。在 CSS 中，1 像素所占的尺寸够 1 英寸中放下 96 像素。很多用户代理忽略这个定义，而是直接使用屏幕上的像素。
缩放页面或打印时要考虑缩放，此时 100px 宽的元素经染后得到的宽度可能大于设备上的 100 个小点。

> 绝对单位在定义文档的印刷样式时非常有用，因为打印机通常使用英寸、点和派卡。

## 像素理论

讲到像素时，CSS 规范建议，如果显示器的像素密度与每英寸 96 像素 (pixels perinch，ppi) 相差特别大，用户代理应该缩放像素度量，使用“参考像素”(referencepixel)。
CSS2 建议用 90ppi 做参考像素，而 CSS2.1 和 CSS3 建议使用 96ppi。对最常见的打印机来说，它用的单位是点，而不是像素，而且每英寸中能放下的点数远超 96!
打印网页时，可以假设每英寸 96 像素，然后据此缩放输出。

## 分辨率单位

## em 和 ex 单位

首先介绍两个联系紧密的单位:em和ex。按CSS的定义，1em等于元素的 font-size属性值。如果元素的 font-size 为14像素,那么对那个元素来说，1em 就等于 14 像素。

ex指所用字体中小写字母x的高度。因此，如果两个段落的字号都是24点，但是使用的字体不同，那么ex的值也不一样。这是因为不同字体中的x高度有所不同

## rem 单位

与em单位类似，rem也基于声明的字号。二者之间的区别是(很微小)，em相对当前元素的字号计算，而rem始终相对根元素计算。在HTML中，根元素是html。
因此，font-size:1rem;声明把元素的字号设为与文档根元素的字号一样大。

## ch 单位

ch。这个单位基本上可以理解为“一个字符

CSS 把 ch单位定义为所用字体中一个零的进宽。这跟em基于元素的 font-size 值计算有点类似。


## 视区相关的单位

### 视区宽度单位(vw)

这个单位根据视区的宽度计算，然后除以100。因此，如果视区的宽度是937像素，那么 1vw 等于 9.37px。如果视区的宽度有变，例如把浏览器窗口拉宽或缩窄，vw的值随之改变。

### 视区高度单位(vh)

这个单位根据视区的高度计算，然后除以100。因此，如果视区的高度是650像素那么 1vh等于6.5px。如果视区的高度有变，例如把浏览器窗口拉高或缩矮，vh的值随之改变。

### 视区尺寸最小值单位(vmin)
这个单位等于视区宽度或高度的1/100，始终取宽度和高度中较小的那个。因此，如果一个视区的宽度为 937像素，高度为650像素，那么1vmin 等于6.5px。

### 视区尺寸最大值单位(vmax)
这个单位等于视区宽度或高度的1/100，始终取宽度和高度中较大的那个。因此，如果一个视区的宽度为 937 像素，高度为650像素，那么1vmax等于 9.37px。

## 计算值

为方便你做数学计算，CSS 提供了calc()值。括号中可以使用简单的数学算式。允许使用的运算符有+(加)、-(减)、*(乘)、/(除)，以及括号。
这些运算符的运算顺序与传统的 PEMDAS(括号、指数、乘、除、加、减)一样，不过这里其实只有PMDAS，因为calc()不允许做指数运算。

```css
input[type="text"]{width: attr(maxlength em);}

<input type="text" maxlength="10">
```

```html
<input type="text" maxlength="10">
```

## rgb

因此，使用百分数表示白色和黑色的方式如下

rgb(100%,100%,100%)
rgb(0%,0%,0%)

使用三个整数表示的方法如下:

rgb(255,255,255)
rgb(0,0,0)


## RGBa 颜色

从CSS3起，上述两种函数式RGB表示法发展成了函数式RGBa表示法。这种表示法在RGB 的三个通道后面增加了一个 alpha值，即“red-green-blue-alpha”，简称 RGBa。
这里的 alpha 指 alpha 通道，用于衡量不透明度。


## HSL和 HSLa 颜色

CSS3新增了HSL 表示法(不过与一般的颜色理论不同)。HSL是Hue(色相)Saturation(饱和度)和Lightness(明度)的简称，
其中色相是角度值，取值范围是0~360,饱和度是从0(无饱和度)~100(完全饱和)的百分数,明度是从0(全)~100(全明)的百分数。

## HSL

饱和度衡量颜色的强度。饱和度为0%时，不管色相角度为多少，得到的都是不太暗的灰色;
饱和度为100%时，在明度一定时，色相最饱满。
明度定义颜色有多暗或多亮。明度为0%时,不管色相和饱和度为多少,始终为黑色;而明度为100%时,得到的是白色。

## 自定义值

自定义标识符以两个连字符开头 (--) 。调用的方法是使用 var() 值类型

```
html {
--base-color: #639;
--highlight-color: #AEA;
}
```


```css
h1 {color: var(--base-color);}
h2 {color: var(--highlight-color);}
```

这些自定义标识符通常被称为“CSS 变量”，这解释了为什么使用 var() 调用它们。这个称呼有点道理，不过要记住，自定义标识符没有编程语言中的变量那样功能全面。
其实,自定义标识符更像是文本编辑器中的宏，作用只是把一个值替换成另一个。
