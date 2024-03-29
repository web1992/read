# 递归

- DFS 深度优先搜索
- 前中后序二叉树遍历
- 汉诺塔
- 走台阶
- 方法或函数调用自身的方式称为递归调用，调用称为递，返回称为归

## 递归需要满足的三个条件

1. 一个问题的解可以分解为几个子问题的解
2. 这个问题与分解之后的子问题，除了数据规模不同，求解思路完全一样
3. 存在递归终止条件

写递归代码最关键的是写出递推公式，找到终止条件。

人脑几乎没办法把整个“递”和“归”的过程一步一步都想清楚。计算机擅长做重复的事情，所以递归正合它的胃口。而我们人脑更喜欢平铺直叙的思维方式。当我们看到递归时，我们总想把递归平铺展开，脑子里就会循环，一层一层往下调，然后再一层一层返回，试图想搞清楚计算机每一步都是怎么执行的，这样就很容易被绕进去。对于递归代码，这种试图想清楚整个递和归过程的做法，实际上是进入了一个`思维误区`。很多时候，我们理解起来比较吃力，主要原因就是自己给自己制造了这种理解障碍。那正确的思维方式应该是怎样的呢？如果一个问题 A 可以分解为若干子问题 B、C、D，你可以`假子问题` B、C、D `已经解决`，在此基础上思考如何解决问题 A。而且，你只需要思考问题 A 与子问题 B、C、D 两层之间的关系即可，不需要一层一层往下思考子问题与子子问题，子子问题与子子子问题之间的关系。屏蔽掉递归细节，这样子理解起来就简单多了。因此，编写递归代码的关键是，只要遇到递归，我们就把它抽象成一个递推公式，不用想一层层的调用关系，不要试图用人脑去分解递归的每个步骤。

## 注意点

- 递归代码要警惕堆栈溢出
- 递归代码要警惕重复计算（重叠子问题）
- 函数调用耗时多
- 空间复杂度高

## 递归树

如果我们把这个一层一层的分解过程画成图，它其实就是一棵树。我们给这棵树起一个名字，叫作递归树。

我这里画了一棵斐波那契数列的递归树，你可以看看。节点里的数字表示数据的规模，一个节点的求解可以分解为左右子节点两个问题的求解。

![recursion-tree.png](./images/recursion-tree.png)