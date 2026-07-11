# 如何使用 TileMap｜Godot 4 教程《勇者传说》#2

> 原作者：瓦格良  
> 原文：[Bilibili 专栏 cv23978148](https://www.bilibili.com/read/cv23978148)  
> 所属文集：[勇者传说｜Godot 笔记](https://www.bilibili.com/read/readlist/rl782393)  
> 本地编号：3/9

---

## 勇者传说 #2

## 场景：

1.选中TileMap节点，切换到底部的TileSet面板

a. 在不想添加的图块上右键选择删除

b. 有些图块是有扩展出去的部分(地面、蘑菇)，比单独图块更好的方法是扩展图块本身

c. 选中【选择】工具，选中有扩展部分的图块，点中小红点向扩展的方向拖动（如果扩展图块在最上面，那么就只能从上向下拖）

![原文图片 1](images/02/001.png)

d. 橙色框表示的是单元格相对于图块的位置，在【选中】=》【渲染】=》【纹理原点】，设置y为8

![原文图片 2](images/02/002.png)

e. 在【绘制】工具中选中纹理原点，调整y值，即可批量操作

![原文图片 3](images/02/003.png)

f. 在【绘制】工具中选中物理层0，按住crtl+shift拖动，即可为所有选中的图块设置物理碰撞层

![原文图片 4](images/02/004.png)

2. 使用地形可自动绘制需要的图块

a. 选中TileMap节点，选择Tile Set属性，展开Terrain Sets，点击添加元素，即可添加一个地形集，选择地形集的图块模式为Match Corners，根据图块角落匹配，在Terrains添加元素就是添加实际地形，取一个有意义的名字(Trunk)

![原文图片 5](images/02/005.png)

b. 选中下方TileSet，选中【绘制】，切换绘制属性为【地形】，Terrain Set选择Terrain Set0,按住crtl+shift拖动即可将所有图块纳入到这个地形集，在Terrain选择Trunk，为图块设置邻接图块匹配规则

![原文图片 6](images/02/006.png)

c. 选中下方TileMap，选中【地形】，选中Trunk地形，即可在编辑器进行绘制

d. 按住crtl+shift直接画大方块，然后再修改细节能获得更高效率

![原文图片 7](images/02/007.png)

e. 选中下方TileSet，在【绘制属性】中选中概率，调整Probability数值，然后涂抹想要降低出现概率的图块

![原文图片 8](images/02/008.png)

f. 装饰图块,利用散布可以使多个选中的图块按照一定概率随机出现

![原文图片 9](images/02/009.png)

g. 选中下方TileSet，在【绘制属性】中选中概率，调整Probability数值，然后涂抹想要降低出现概率的图块

h. 在TileMap节点的Layers属性中，将默认给的图层命名为Geometry,点击下方添加元素，再添加一个图层，命名为ForeGround

![原文图片 10](images/02/010.png)

i. 隐藏地图边界

![原文图片 11](images/02/011.png)

j. 再添加一个图层，命名为Background，并将图层拖动到最上方，在Terrain Sets的Terrains中添加一个地形，起名为Leaves

![原文图片 12](images/02/012.png)

k. 将较少用的图块设置概率为0.3

![原文图片 13](images/02/013.png)

l. 设置地形邻接匹配规则

![原文图片 14](images/02/014.png)

m. 选择TileMap的地形，如果没有出现Leaves，那么先关掉TileMap再打开即可，选择Background图层，开始绘制

![原文图片 15](images/02/015.png)

![原文图片 16](images/02/016.png)
