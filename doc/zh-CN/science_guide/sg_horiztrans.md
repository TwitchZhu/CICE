# 水平输运

我们希望求解每个冰厚类别 $n$ 的面积分数所满足的连续性方程或输运方程（见[示踪物](sg_tracers.md)中的冰面积守恒方程）。该方程描述水平输运时冰面积的守恒。它由[基本变量](sg_fundvars.md)中的冰厚分布方程离散化得到，并忽略右侧分别处理的第二、第三项；相关处理见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。

冰体积、雪体积、冰能量和雪能量有类似守恒方程；后两者为：

$$
\frac{\partial e_{ink}}{\partial t}+\nabla\cdot(e_{ink}\mathbf u)=0,
\qquad
\frac{\partial e_{snk}}{\partial t}+\nabla\cdot(e_{snk}\mathbf u)=0.
$$

默认假定冰雪密度恒定，因此体积守恒等同于质量守恒。若冰雪层密度可变，可定义对应密度示踪物，使其守恒输运；具体方法见 `ice_transport_remap.F90` 开头的说明。未来版本可能加入冰和／或雪密度的预报方程，目前尚未实现。

可使用两种输运方案：迎风方案（upwind scheme），以及原文所引 Dukowicz 2000 提出、Lipscomb 2004 针对海冰修改的增量重映射方案（incremental remapping scheme）。

- 迎风方案使用 T 网格单元东面和北面的速度点，即 E 点的 $uvelE=u$、N 点的 $vvelN=v$。因此 C 网格预报速度分量 $uvelE$ 和 $vvelN$ 可直接传给迎风输运方案。若在 B 网格上使用迎风方案，先把 B 网格 U 点的 $uvelU$、$vvelU$（分别对应 $u$、$v$）插值到 E 点和 N 点。注意，迎风方案并不输运所有可能启用的示踪物。
- 重映射天然适合 B 网格，因为它用角点（U 点）的 $uvelU$、$vvelU$ 计算出发点。不过，先将 C 网格的 $uvelE$、$vvelN$ 插值到 U 点，也可以在 C 网格上使用重映射。

重映射方案具有以下优点：

- 守恒所输运的量（面积、体积或能量）。
- 不产生振荡，即不在输运场中制造虚假的波纹。
- 保持示踪物的单调性：不在厚度和焓场中制造新的极值；$m+1$ 时刻的值受 $m$ 时刻的值界定。
- 具有空间二阶精度，数值扩散远小于迎风等一阶方案；为了保持单调性，局部精度可能降低至一阶。
- 对大量冰厚类别或示踪物较高效。大量工作是几何计算，每个网格单元只需进行一次，而不必为每个输运量重复。

时间步长必须保证从网格单元角点向后投影的轨迹仍在周围四个单元内。这正是“增量”重映射区别于一般重映射的限制。由此得到类似 CFL 的条件：

$$
\frac{\max|\mathbf u|\Delta t}{\Delta x}\le1.
$$

若速度场高度辐散，为避免轨迹交叉，最大时间步长还须缩小一半。不过在气候模式中，海冰速度场每个时间步的辐散相对于网格大小通常较小。

重映射算法可概括为：

1. 依据各单元内冰面积和示踪物场的平均值，构造这些场的线性近似，并限制梯度以保持单调性。
2. 根据单元角点冰速确定穿过各单元边缘的通量所对应的出发区域，将其划分为三角形并计算顶点坐标。
3. 在出发三角形上积分面积场和示踪物场，求得穿过各单元边缘的面积、体积和能量。
4. 根据这些输运量更新状态变量。

所有标量场由同一个速度场输运，所以第 2 步每个时间步只需执行一次；另外三步须对各冰厚类别中的每个场重复执行。下文说明这些步骤。

输运计算后，单元内冰面积与开阔水面面积之和可能不等于 1。[Icepack](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html) 中的力学变形参数化通过形成压力脊和开阔水面，使二者重新相加为 1。

## 重建面积和示踪物场

首先，根据已知状态变量，把每个网格单元内的冰面积和示踪物场重建为 $x$、$y$ 的线性函数。对每个场，计算单元中心的值（即该单元局部二维笛卡尔坐标系的原点）以及 $x$、$y$ 方向梯度。为了保持单调性，需要限制梯度。重建场在整个单元上积分后的平均值必须等于已知状态变量；面积分数记为 $\bar a$，厚度记为 $\tilde h$，焓记为 $\hat q$。平均值通常不等于单元中心值。例如，平均冰面积应等于形心处的值，而形心可能不在单元中心。

先考虑冰面积分数；它相当于原文所引 Dukowicz 2000 中的流体密度 $\rho$。对每个冰厚类别，构造均值为 $\bar a$ 的场 $a(\mathbf r)$，其中 $\mathbf r=(x,y)$ 是相对单元中心的位置向量。要求：

$$
\int_A a\,dA=\bar a A,
$$

其中 $A=\int_A dA$ 为网格单元面积。只要 $a(\mathbf r)$ 满足下式，便符合该要求：

$$
a(\mathbf r)=\bar a+\alpha_a\langle\nabla a\rangle\cdot(\mathbf r-\bar{\mathbf r}).
$$

$\langle\nabla a\rangle$ 是单元内面积梯度的中心估计；$\alpha_a$ 是保证单调性的限制系数；$\bar{\mathbf r}$ 是单元形心：

$$
\bar{\mathbf r}=\frac{1}{A}\int_A\mathbf r\,dA.
$$

因此，单元中心（$\mathbf r=0$）的冰面积为：

$$
a_c=\bar a-a_x\bar x-a_y\bar y.
$$

其中 $a_x=\alpha_a(\partial a/\partial x)$、$a_y=\alpha_a(\partial a/\partial y)$ 是受限的 $x$、$y$ 方向梯度。形心分量 $\bar x=\int_Ax\,dA/A$、$\bar y=\int_Ay\,dA/A$ 通过下文“积分各场”中的三角形积分公式求得。这些均值和 $\overline{x^2}$、$\overline{xy}$、$\overline{y^2}$ 等高阶均值只计算一次并存储。

接着考虑冰雪厚度场和焓场。厚度对应 Dukowicz 2000 中的示踪物浓度 $T$，但该文没有与焓对应的量。重建后的冰雪厚度 $h(\mathbf r)$ 和焓 $q(\mathbf r)$ 必须满足：

$$
\int_Aah\,dA=\bar a\tilde hA,
\qquad
\int_Aahq\,dA=\bar a\tilde h\hat qA.
$$

$\tilde h=h(\tilde{\mathbf r})$ 是冰面积中心处的厚度；$\hat q=q(\hat{\mathbf r})$ 是冰雪体积中心处的焓。若厚度和焓满足以下形式，上述条件便成立：

$$
h(\mathbf r)=\tilde h+\alpha_h\langle\nabla h\rangle\cdot(\mathbf r-\tilde{\mathbf r}),
\qquad
q(\mathbf r)=\hat q+\alpha_q\langle\nabla q\rangle\cdot(\mathbf r-\hat{\mathbf r}),
$$

其中 $\alpha_h$、$\alpha_q$ 是限制系数。冰面积中心 $\tilde{\mathbf r}$ 和冰雪体积中心 $\hat{\mathbf r}$ 分别为：

$$
\tilde{\mathbf r}=\frac{1}{\bar a A}\int_Aa\mathbf r\,dA,
\qquad
\hat{\mathbf r}=\frac{1}{\bar a\tilde hA}\int_Aah\mathbf r\,dA.
$$

计算积分后，冰面积中心的分量为：

$$
\tilde x=\frac{a_c\bar x+a_x\overline{x^2}+a_y\overline{xy}}{\bar a},
\qquad
\tilde y=\frac{a_c\bar y+a_x\overline{xy}+a_y\overline{y^2}}{\bar a}.
$$

冰雪体积中心的分量为：

$$
\hat x=\frac{c_1\bar x+c_2\overline{x^2}+c_3\overline{xy}+c_4\overline{x^3}+c_5\overline{x^2y}+c_6\overline{xy^2}}{\bar a\tilde h},
$$

$$
\hat y=\frac{c_1\bar y+c_2\overline{xy}+c_3\overline{y^2}+c_4\overline{x^2y}+c_5\overline{xy^2}+c_6\overline{y^3}}{\bar a\tilde h},
$$

其中：

$$
\begin{aligned}
c_1&=a_ch_c, & c_2&=a_ch_x+a_xh_c, & c_3&=a_ch_y+a_yh_c,\\
c_4&=a_xh_x, & c_5&=a_xh_y+a_yh_x, & c_6&=a_yh_y.
\end{aligned}
$$

根据厚度与焓的重建式，单元中心的厚度和焓为：

$$
h_c=\tilde h-h_x\tilde x-h_y\tilde y,
\qquad
q_c=\hat q-q_x\hat x-q_y\hat y,
$$

其中 $h_x$、$h_y$、$q_x$、$q_y$ 是厚度和焓的受限梯度。表面温度与冰雪厚度采用相同处理方式，但不对应焓。依附于冰体积和雪体积的示踪物分别类比冰焓和雪焓处理。

为保持单调性，方案使用 van Leer 限制。设 $\bar\phi(i,j)$ 是单元 $(i,j)$ 中某场的平均值。先计算 $\bar\phi$ 在 $x$、$y$ 方向的中心梯度，再检查这些梯度重建的单元内 $\phi$ 是否超出本单元及其八个邻居中 $\bar\phi$ 的范围。设 $\bar\phi_{max}$、$\bar\phi_{min}$ 是这九个单元的最大、最小均值，$\phi_{max}$、$\phi_{min}$ 是本单元重建场的最大、最小值。因重建为线性函数，极值位于单元角点。若 $\phi_{max}>\bar\phi_{max}$ 或 $\phi_{min}<\bar\phi_{min}$，将未受限梯度乘以 $\alpha=\min(\alpha_{max},\alpha_{min})$，其中：

$$
\alpha_{max}=\frac{\bar\phi_{max}-\bar\phi}{\phi_{max}-\bar\phi},
\qquad
\alpha_{min}=\frac{\bar\phi_{min}-\bar\phi}{\phi_{min}-\bar\phi}.
$$

否则不必限制梯度。

CICE v3.14 及更早版本在物理空间中计算梯度。从 v4.0 开始，梯度在缩放后的空间中计算；每个单元的边长为 1，原点位于单元中心，四个顶点为 $(0.5,0.5)$、$(-0.5,0.5)$、$(-0.5,-0.5)$、$(0.5,-0.5)$。在这个坐标系下，上述某些单元均值因是 $x$ 和／或 $y$ 的奇函数而为零，但代码仍保留它们以保持一般性。

## 确定出发三角形

原文所引 Dukowicz 2000 详细讨论了确定出发三角形（departure triangles）的方法。下图中的阴影四边形是出发区域，其内容被输运到标为 $H$ 的目标网格单元。邻近单元用方位 $NW$、$N$、$NE$、$W$、$E$ 标示。四个向量沿单元角点的速度场指向；连接这些向量的起点即得到出发区域。

![出发区域](../../source/science_guide/figures/deparr.png)

与在整个出发区域上积分相比，计算穿过单元边缘的通量更方便。对每个单元确定北边缘和东边缘的出发区域；它们同时也是邻居单元的南边缘和西边缘。以 $H$ 的北边缘为例，通量来自 $NW$ 和 $N$ 单元。$NW$ 的贡献区域是顶点为 $abc$ 的三角形；$N$ 的贡献区域是可分成 $acd$、$ade$ 两个三角形的四边形。对于 $abc$，先以角点 $a$ 为参考，用欧氏几何确定顶点 $b$、$c$ 的坐标；再将三个顶点转换到以 $NW$ 单元中心为原点的坐标系。这一步使场能在其重建坐标系中积分。对每个网格单元的北、东边缘重复上述过程，即得到所有对应的出发三角形顶点。

图中阴影出发区域由四个角点向后追踪的轨迹连接而成，并以增量重映射方式映射到 $H$ 单元。穿过 $H$ 北边缘的区域由 $NW$ 单元中的三角形 $abc$，以及 $N$ 单元中由 $acd$、$ade$ 构成的四边形组成。

![所有可能对北边缘通量作出贡献的三角形](../../source/science_guide/figures/triangles.png)

上图转载自 Dukowicz 2000，展示了可能穿过一个单元北边缘的全部 20 个三角形。它们可分为五组，每组四个互斥三角形。下表中，$(x_1,y_1)$、$(x_2,y_2)$ 分别是相对西北和东北角点的出发点笛卡尔坐标。连接两出发点的直线在西边缘交于相对西北角点的 $(0,y_a)$，在东边缘交于相对东北角点的 $(0,y_b)$。东边缘三角形及其选择条件与此相同，只需旋转 90°。

定义：若 $x_1>0$，$\tilde y_1=y_1$，否则 $\tilde y_1=y_a$；若 $x_2<0$，$\tilde y_2=y_2$，否则 $\tilde y_2=y_b$。下表给出北边缘 20 个三角形的选择逻辑。

| 组 | 三角形 | 选择条件 |
| --- | --- | --- |
| 1 | NW | $y_a>0,\ y_1\ge0,\ x_1<0$ |
| 1 | NW1 | $y_a<0,\ y_1\ge0,\ x_1<0$ |
| 1 | W | $y_a<0,\ y_1<0,\ x_1<0$ |
| 1 | W2 | $y_a>0,\ y_1<0,\ x_1<0$ |
| 2 | NE | $y_b>0,\ y_2\ge0,\ x_2>0$ |
| 2 | NE1 | $y_b<0,\ y_2\ge0,\ x_2>0$ |
| 2 | E | $y_b<0,\ y_2<0,\ x_2>0$ |
| 2 | E2 | $y_b>0,\ y_2<0,\ x_2>0$ |
| 3 | W1 | $y_a<0,\ y_1\ge0,\ x_1<0$ |
| 3 | NW2 | $y_a>0,\ y_1<0,\ x_1<0$ |
| 3 | E1 | $y_b<0,\ y_2\ge0,\ x_2>0$ |
| 3 | NE2 | $y_b>0,\ y_2<0,\ x_2>0$ |
| 4 | H1a | $y_ay_b\ge0,\ y_a+y_b<0$ |
| 4 | N1a | $y_ay_b\ge0,\ y_a+y_b>0$ |
| 4 | H1b | $y_ay_b<0,\ \tilde y_1<0$ |
| 4 | N1b | $y_ay_b<0,\ \tilde y_1>0$ |
| 5 | H2a | $y_ay_b\ge0,\ y_a+y_b<0$ |
| 5 | N2a | $y_ay_b\ge0,\ y_a+y_b>0$ |
| 5 | H2b | $y_ay_b<0,\ \tilde y_2<0$ |
| 5 | N2b | $y_ay_b<0,\ \tilde y_2>0$ |

该方案最初为矩形网格设计。CICE 的网格单元实际位于球面上，必须投影到平面。CICE 的投影把每个单元映射为边长为 1 的正方形。穿过一个单元边缘的出发三角形在以该边缘中点为原点、顶点为 $(-0.5,0)$ 和 $(0.5,0)$ 的坐标系中计算。交点按照相邻边成直角的笛卡尔几何求得。

设 $CL$、$CR$ 为左、右角点，由线段 $CLR$ 相连；$DL$、$DR$ 为出发点，由线段 $DLR$ 相连。再设 $IL=(0,y_a)$、$IR=(0,y_b)$ 为交点，$IC=(x_c,0)$ 为 $CLR$ 与 $DLR$ 的交点。$y_a$、$y_b$ 和 $x_c$ 可写为：

$$
\begin{aligned}
y_a&=\frac{x_{CL}(y_{DM}-y_{DL})+x_{DM}y_{DL}-x_{DL}y_{DM}}{x_{DM}-x_{DL}},\\
y_b&=\frac{x_{CR}(y_{DR}-y_{DM})-x_{DM}y_{DR}+x_{DR}y_{DM}}{x_{DR}-x_{DM}},\\
x_c&=x_{DL}-y_{DL}\frac{x_{DR}-x_{DL}}{y_{DR}-y_{DL}}.
\end{aligned}
$$

每个出发三角形由 $CL$、$CR$、$DL$、$DR$、$IL$、$IR$、$IC$ 七个点中的三个确定。

给定二维速度场 $\mathbf u$，B 网格中某单元的辐散度 $\nabla\cdot\mathbf u$ 可由局部速度计算，并以穿过各边缘的通量表示：

$$
\nabla\cdot\mathbf u=\frac{1}{A}\left[
\frac{u_{NE}+u_{SE}}{2}L_E+
\frac{u_{NW}+u_{SW}}{2}L_W+
\frac{u_{NE}+u_{NW}}{2}L_N+
\frac{u_{SE}+u_{SW}}{2}L_S
\right].
$$

其中 $L$ 为边长，下标 $N,S,E,W$ 表示方位。该式等同于 EVP 动力学中计算的辐散度。但此式中的通量一般不等于前述出发区域方案隐含的通量。某些应用希望通过指定每条边缘的出发区域面积来指定辐散度，这称为**边缘通量调整**（edge flux adjustment，EFA）。当 `l_edge_flux_adj=true` 时使用 EFA。此时重映射例程计算指定的出发面积 `edgearea_e`、`edgearea_n`，并为每个出发区域构造一个额外三角形，使总面积与指定值相等。

这一方法由挪威南森环境与遥感中心的 Mats Bentsen 提议并首次实现；他曾把早期 CICE 重映射方案用于海洋模式。CICE 的实现更加一般，允许出发区域位于单元边缘的两侧。额外三角形必须位于共享该边缘的两个单元之一，不能同时跨两者。

B 网格默认 `l_edge_flux_adj=false`。但 C 网格的理想化测试表明，设为假时海冰密集度等预报场会出现棋盘格模式（原文引用 Lemieux 2024）。因此在 C 网格上该逻辑变量设为真；此时边缘面积 `edgearea_e`、`edgearea_n` 由 C 网格速度分量 $uvelE$、$vvelN$ 计算。

确定三角形时，CICE 对 Dukowicz 2000 的方案还作了另一项修改。该文直接将角点速度向后投影以确定出发点：

$$
\mathbf x_D=-\mathbf u\Delta t,
$$

其中 $\mathbf x_D$ 是相对单元角点的出发点位置，$\mathbf u$ 是角点速度。该近似仅具有一阶精度；估计轨迹中点处的速度可提高精度。

## 积分各场

接下来，在出发三角形上积分重建场，求得穿过每条单元边缘的总面积、体积和能量。由于面积场是 $x$、$y$ 的线性函数，面积输运较易计算。设三角形顶点为 $\mathbf x_i=(x_i,y_i)$，$i\in\{1,2,3\}$，则其面积为：

$$
A_T=\frac12\left|(x_2-x_1)(y_3-y_1)-(y_2-y_1)(x_3-x_1)\right|.
$$

任意线性函数 $f(\mathbf r)$ 在三角形上的积分为：

$$
F_a=A_Tf(\mathbf x_0),
\qquad
\mathbf x_0=\frac13\sum_{i=1}^{3}\mathbf x_i,
$$

其中 $\mathbf x_0$ 为三角形重心。计算面积输运时，在重心求 $a(\mathbf x_0)=a_c+a_xx_0+a_yy_0$，再乘以 $A_T$。按约定，向北和向东输运为正，向南和向西输运为负。

上式不能用于体积输运，因为重建后的体积是位置的二次函数，即面积与厚度两个线性函数的乘积。二次多项式在三角形上的积分需要在三个点求值：

$$
F_h=\frac{A_T}{3}\sum_{i=1}^{3}f(\mathbf x'_i),
\qquad
\mathbf x'_i=\frac{\mathbf x_0+\mathbf x_i}{2}.
$$

这些点位于重心和三个顶点之间的中点。Dukowicz 2000 用此公式计算 $\rho T$ 的输运，与冰体积相似。它不适用于冰雪能量，因为能量是面积、厚度和焓的乘积，属于三次函数。三次多项式在三角形上的积分可用四点公式（原文引用 Stroud 1971）：

$$
F_q=A_T\left[-\frac{9}{16}f(\mathbf x_0)
+\frac{25}{48}\sum_{i=1}^{3}f(\mathbf x''_i)\right],
\qquad
\mathbf x''_i=\frac{3\mathbf x_0+2\mathbf x_i}{5}.
$$

在指定点求函数值时，须计算许多 $a(\mathbf x)h(\mathbf x)$ 和 $a(\mathbf x)h(\mathbf x)q(\mathbf x)$ 形式的乘积；每项都是单元中心值与两个位移项之和。代码通过存储反复使用的部分和来加速计算。

## 更新状态变量

最后，计算每个冰厚类别和网格单元中的新状态值。新的冰面积分数 $a'_{in}(i,j)$ 为：

$$
a'_{in}(i,j)=a_{in}(i,j)+
\frac{F_{aE}(i-1,j)-F_{aE}(i,j)+F_{aN}(i,j-1)-F_{aN}(i,j)}{A(i,j)}.
$$

$F_{aE}(i,j)$ 和 $F_{aN}(i,j)$ 分别是穿过单元 $(i,j)$ 东边缘和北边缘的面积输运，$A(i,j)$ 是单元面积。加入一个单元的输运量会从其邻居单元扣除，因此该式守恒总冰面积。

新冰体积和能量以类似方式计算。新厚度为体积与面积之比，新焓为能量与体积之比。示踪物的单调性由下式保证：

$$
h'=\frac{\int_Aah\,dA}{\int_Aa\,dA},
\qquad
q'=\frac{\int_Aahq\,dA}{\int_Aah\,dA}.
$$

这里 $h'$、$q'$ 是新时刻的厚度和焓，通过在面积为 $A$ 的拉格朗日出发区域上积分旧时刻的冰面积、体积和能量求得。也就是说，它们是旧值以非负权重 $a$、$ah$ 计算的加权平均。因此新值必须位于旧值的最大和最小值之间。

原文：[sg_horiztrans.rst](../../source/science_guide/sg_horiztrans.rst)
