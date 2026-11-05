# 与其他气候模式组件耦合

海冰模式通过通量耦合器（flux coupler）与其他模式组件交换信息。CICE 已采用多种耦合技术接入许多气候模式。本文主要以 NCAR 的 CESM 通量耦合器（原文引用 Kauffman 2002）为背景；CESM 是第一个大规模纳入 CICE 的气候模式。通量耦合器最初用于收集各组件的状态变量、计算模式界面上的通量，再把这些通量返回各组件，供下一积分时段使用，同时保持动量、热量和淡水守恒。

现在部分通量改在海冰模式内部计算，再交给耦合器分发给其他组件，原因有二。首先，有些通量与海冰状态强烈相依，反之亦然；为了保持一致性和稳定性，必须隐式、同步地确定冰状态和表面通量。其次，一个网格单元内可能有多种冰类型，让海冰模式确定网格单元的总体冰特征并提供相应通量，比逐一传递各类冰的多个状态变量更高效。

海冰模式与 CESM 耦合器之间交换的通量和状态变量列于 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。按约定，有方向的通量以向下为正。在 CESM 中，海冰模式交换耦合通量时可以使用与计算网格不同的网格；通过 namelist 变量 `gridcpl_file` 启用。另一个 namelist 变量 `highfreq` 可启用区域北极系统模式（Regional Arctic System Model，RASM）实现的高频耦合过程。特别是计算大气边界层湍流通量时，使用大气与海冰之间的相对速度 $\vec U_a-\vec u$，而非完整的大气速度。

冰面积分数（ice fraction）$a_i$，即 `aice`，是网格单元中被海冰覆盖的总面积比例：

$$
\begin{cases}
a_i=0, & \text{没有海冰；}\\
a_i=1, & \text{没有开阔水面；}\\
0<a_i<1, & \text{海冰与开阔水面并存。}
\end{cases}
$$

$a_i$ 等于各冰厚类别面积分数之和。耦合器使用冰面积分数将海冰模式通量与其他组件的通量合并。例如，将以 $a_i$ 加权的透入短波辐射通量，与以 $1-a_i$ 加权、穿过无冰裂隙的净短波辐射通量合并，得到整个网格单元进入海洋的净短波通量。耦合器要求将通量除以总冰面积，以便对冰和陆地模式采用相同处理方式，因为陆地也可能只占大气网格单元的一部分。因此，这些通量以**单位海冰面积**而非**单位网格单元面积**表示。

在 CICE 独立运行（即不耦合）时，`ice_forcing.F90` 提供 AOMIP 的短波和长波辐射公式。`longwave_rosati_miyakoda` 函数中的向下长波辐射为：

$$
F_{lw\downarrow}=\epsilon\sigma T_s^4
-\epsilon\sigma T_a^4(0.39-0.05e_a^{1/2})(1-0.8f_{cld})
-4\epsilon\sigma T_a^3(T_s-T_a).
$$

其中，大气水汽压（mb）$e_a=1000Q_a/(0.622+0.378Q_a)$；$\epsilon=0.97$ 是海洋发射率（emissivity）；$\sigma$ 是斯特藩—玻尔兹曼常数；$f_{cld}$ 是云量分数；$T_a$ 是近地面气温（K）。右侧第一项表示由平均（合并）海冰与海洋表面温度 $T_s$（K）产生的向上长波辐射，其他项表示参考原文所引 Rosati 1988 形式的净长波辐射。

`longwave_parkinson_washington` 函数还提供原文所引 Parkinson 1979 的向下长波公式：

$$
F_{lw\downarrow}=\epsilon\sigma T_a^4
\left(1-0.261\exp\left(-7.77\times10^{-4}T_a^2\right)
\left(1+0.275f_{cld}\right)\right).
$$

$F_{lw\uparrow}$ 对各冰厚类别取不同值，而 $F_{lw\downarrow}$ 取决于所有冰厚类别和开阔水面的平均表面温度。该公式中的海冰—海洋合并温度使长波辐射与海表温度之间产生不真实的反馈。因此在独立运行模式中，改变发射率等辐射设置会导致错误的模式敏感性。虽然独立模式测试配置对开发有用，但项目强烈建议只根据与其他地球系统组件耦合的模式模拟得出科学结论。

`compute_shortwave` 子程序中的 AOMIP 短波强迫公式，通过大气水汽压引入云量和湿度：

$$
F_{sw\downarrow}=\frac{1353\cos^2Z}{10^{-3}(\cos Z+2.7)e_a+1.085\cos Z+0.1}
\left(1-0.6f_{cld}^3\right)>0,
$$

其中 $\cos Z$ 是太阳天顶角的余弦。

许多海冰模式根据海洋模式或其他数据源提供的地转洋流（geostrophic ocean currents）计算海面坡度 $\nabla H_\circ$。在 POP 中，海面高度 $H_\circ$ 是预报变量，因此耦合器可以直接提供海面坡度，而不必从海流推断；`dyn_prep2` 子程序也提供了根据海流计算坡度的选项。海冰模式使用表层洋流 $\vec U_w$ 计算海洋与海冰之间的应力，进而计算冰速 $\vec u$。相对于海冰的应力为：

$$
\vec\tau_w=c_w\rho_w\left|\vec U_w-\vec u\right|
\left[(\vec U_w-\vec u)\cos\theta
+\hat k\times(\vec U_w-\vec u)\sin\theta\right].
$$

该应力随后以相对于海洋的形式传递给通量耦合器，供海洋模式使用。其中，$\theta$ 为地转流与表层流之间的偏转角，$c_w$ 为海洋拖曳系数，$\rho_w$ 为海水密度，$\hat k$ 为垂直单位向量。如果海洋模式最上层无法解析边界层中的埃克曼螺旋（Ekman spiral），就需要此偏转角；如果最上层相对于典型埃克曼螺旋深度足够薄，则 $\theta=0$ 是合理近似。

关于大气与海洋强迫及通量耦合器和海冰模式之间交换的其他数据，请参阅 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。

原文：[sg_coupling.rst](../../source/science_guide/sg_coupling.rst)
