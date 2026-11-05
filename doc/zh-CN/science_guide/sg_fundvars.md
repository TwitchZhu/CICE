# 基本变量

北极和南极海冰是开阔水面、较薄的一年冰、较厚的多年冰及厚压力脊的混合体。冰盖的热力学和动力学性质取决于各厚度范围内的冰量。因此，海冰模拟的基本问题是描述**冰厚分布**（ice thickness distribution，ITD）在时间和空间上的演变。

除冰厚分布外，CICE 还可选择使用**冰块尺寸分布**（floe size distribution，FSD）。已有冰块的垂直和侧向生长或融化、新冰形成、波浪破碎，以及结冰条件下的冰块黏结，都会改变冰块的水平尺寸。FSD 是刻画这一变异性的概率函数。该方案基于原文所引 Horvat 2015 的**冰块尺寸与厚度联合分布**（joint floe size and thickness distribution，FSTD）理论框架，由 Roach 2018 和 Roach 2019 实现。联合冰块尺寸分布作为面积加权示踪物输运，定义为某一冰厚类别中、水平尺寸属于给定冰块尺寸组的冰面积比例。此功能包含海冰与海面波浪的相互作用。为测试提供了某一时刻的海浪谱输入，但与其他 CICE 数据集一样，不应将其用于生产模拟或发表结果。不建议在没有海浪输入的情况下使用 FSD。有关 CICE 的 ITD 和联合 FSTD，另见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。

CICE 求解的基本方程（原文引用 Thorndike 1975）为：

$$
\frac{\partial g}{\partial t}
=-\nabla\cdot(g\mathbf u)
-\frac{\partial}{\partial h}(fg)+\psi.
$$

其中，$\mathbf u$ 是水平冰速，$\nabla=(\partial/\partial x,\partial/\partial y)$，$f$ 是热力学冰生长速率，$\psi$ 是压力脊再分配函数，$g$ 是冰厚分布函数。$g(\mathbf x,h,t)\,dh$ 定义为在给定时间和位置，厚度位于 $(h,h+dh)$ 范围内的海冰覆盖面积比例。

除了冰面积分数 $a_{in}$，对每个类别 $n$ 还定义以下状态变量。与早期 CICE 版本不同，雪和冰的能量不再作为独立变量保存，而是连同海冰盐度，作为依附于雪体积和冰体积的示踪物保存。

- $v_{in}$：冰体积，等于 $a_{in}$ 与冰厚 $h_{in}$ 的乘积。
- $v_{sn}$：雪体积，等于 $a_{in}$ 与雪厚 $h_{sn}$ 的乘积。
- $e_{ink}$：第 $k$ 冰层的内部能量，等于冰层体积 $v_{in}/N_i$ 与冰层焓 $q_{ink}$ 的乘积。$N_i$ 是冰层总数，默认 $N_i=4$。$q_{ink}$ 是融化单位体积海冰并将其温度升至 0 °C 所需能量的负值。当前代码中 $e_i<0$、$q_i<0$，且 $e_i=v_iq_i$。
- $e_{snk}$：第 $k$ 雪层的内部能量，等于雪层体积 $v_{sn}/N_s$ 与雪层焓 $q_{snk}$ 的乘积，$N_s$ 为雪层数。雪的能量在代码中同样为负值。CICE 允许多层雪，默认 $N_s=1$。
- $S_i$：第 $k$ 层的海冰总体含盐量，等于冰层体积与海冰盐度示踪物的乘积。
- $T_{sfn}$：表面温度。

由于面积分数无量纲，体积变量的单位为米，即每平方米网格单元面积对应的冰雪立方米数；能量变量的单位为 J/m²。

基本方程右侧的三个项描述三种海冰输运：（1）$(x,y)$ 空间中的水平输运；（2）热力学生长和融化使海冰在厚度空间 $h$ 中移动；（3）压力脊和其他力学过程使海冰在厚度空间中再分配。模式采用**算子分裂**（operator splitting），分三个阶段求解，每个阶段都把三个右侧项中的两个设为零。

水平输运使用原文所引 Dukowicz 2000 的**增量重映射**（incremental remapping）方案，并由 Lipscomb 2004 将其用于海冰，详见[水平输运](sg_horiztrans.md)。厚度空间中的冰输运使用原文所引 Lipscomb 2001 的重映射方案。力学再分配方案基于 Thorndike 1975、Rothrock 1975、Hibler 1980、Flato 1995 和 Lipscomb 2007，概要见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。

求解水平输运和压力脊方程需要冰速 $\mathbf u$；计算厚度空间输运需要知道各类别的冰生长速率 $f$。冰速通过弹性黏塑性（elastic-viscous-plastic，EVP）海冰动力学方案（原文引用 Hunke 1997 及其后续修订）或新的弹性各向异性塑性（elastic-anisotropic-plastic）方案（原文引用 Wilchinsky 2006、Weiss 2009、Tsamados 2013）求得，详见[动力学](sg_dynamics.md)。$f$ 则由热力学模式计算。

代码中的计算顺序旨在使传给耦合器的各量彼此一致，并尽可能反映最新状态。Delta-Eddington 辐射方案同时计算反照率和短波分量。为了在时间步末向耦合器提供最新值，辐射计算顺序作了调整：冰状态经过热力学和动力学更新后，才计算反照率和短波分量，使它们与时间步末的冰面积和厚度一致；但此时所用的向下短波辐射仍来自时间步开始。下一个时间步开始时，不使用新的向下短波强迫重新计算反照率和短波分量，而是按新强迫对上一步末计算的短波分量进行缩放。

Icepack 可以根据最小面积和质量参数 `itd_area_min`、`itd_mass_min` 以守恒方式移除残余海冰。把这两个参数设为 CICE namelist 中的 `dyn_area_min`、`dyn_mass_min`，可避免 Icepack 单柱物理和 CICE 动力计算处理残余海冰时不一致。两项动力阈值应保持较小，以免移除过多海冰。默认行为是把单柱物理的 ITD 阈值设为 namelist 中的动力阈值。也可在 `ice_in` 中另行设置 `itd_area_min`、`itd_mass_min`；设为零会完全关闭残余海冰清除。

原文：[sg_fundvars.rst](../../source/science_guide/sg_fundvars.rst)
