# 动力学

海冰每单位面积的力平衡由二维动量方程表示（原文引用 Hibler 1979）；该方程由三维方程沿冰厚方向积分得到：

$$
m\frac{\partial\mathbf u}{\partial t}
=\nabla\cdot\boldsymbol\sigma
+\vec\tau_a+\vec\tau_w+\vec\tau_b
-\hat k\times mf\mathbf u-mg\nabla H_\circ.
$$

其中 $m$ 是每单位面积的冰雪总质量，$\vec\tau_a$、$\vec\tau_w$ 分别为风应力和海洋应力。$\vec\tau_b$ 是海底应力（seabed stress，也称底部应力），表示浅水区压力脊触底的作用（原文引用 Lemieux 2016）。海冰的力学性质由内部应力张量（internal stress tensor）$\sigma_{ij}$ 表示。右侧另两项分别对应科里奥利作用和海面坡度。为了与低海冰密集度区域的自由漂移（free drift）形式理论一致，风应力和海冰—海洋应力的参数化中必须以冰密集度为乘数。原文所引 Hunke 2003 和 Connolley 2004 详细解释了这一问题及其连续介质解。

动量方程的两个分量写为：

$$
\begin{aligned}
m\frac{\partial u}{\partial t}={}&\frac{\partial\sigma_{1j}}{\partial x_j}+\tau_{ax}
+a_ic_w\rho_w|\mathbf U_w-\mathbf u|
[(U_w-u)\cos\theta\mp(V_w-v)\sin\theta]
-C_bu+mfv-mg\frac{\partial H_\circ}{\partial x},\\
m\frac{\partial v}{\partial t}={}&\frac{\partial\sigma_{2j}}{\partial x_j}+\tau_{ay}
+a_ic_w\rho_w|\mathbf U_w-\mathbf u|
[\pm(U_w-u)\sin\theta+(V_w-v)\cos\theta]
-C_bv-mfu-mg\frac{\partial H_\circ}{\partial y}.
\end{aligned}
$$

在 B 网格上，$u$、$v$ 分量位于同一 U 点，方程也在 U 点求解。在 C 网格上，两分量不共点：$u$ 位于 E 点，$v$ 位于 N 点。B 网格的空间离散依据原文所引 Hunke 1997 和 Hunke 2002 的变分法。应力项 $\partial\sigma_{ij}/\partial x_j$ 使用双线性离散，使离散方程能够从曲线坐标中的连续方程推导而来，并显式纳入网格曲率对应的度量项。详情见 Hunke 2002。C 网格则使用有限差分空间离散，依据原文所引 Bouillon 2009、Bouillon 2013 和 Kimmritz 2016。

CICE 可采用多种海冰流变（rheology）和动量方程求解方法：采用隐式方法的黏塑性（viscous-plastic，VP）流变；在 VP 基础上修改的弹性黏塑性（elastic-viscous-plastic，EVP）模式；修订版 EVP（revised EVP，rEVP）；以及显式考虑海冰覆盖在连续介质以下尺度各向异性的弹性各向异性塑性（elastic-anisotropic-plastic，EAP）模式。Namelist 中 `kdyn=1` 使用 EVP（`ice_dyn_evp.F90`），`kdyn=2` 使用 EAP（`ice_dyn_eap.F90`），`kdyn=3` 使用 VP（`ice_dyn_vp.F90`）。设置 `kdyn=1` 且 `revised_evp=true` 可使用 rEVP。

在风强迫相关的时间尺度上，EVP 退化为 VP；EAP 则退化为原文所引 Wilchinsky 2006 和 Tsamados 2013 详细描述的各向异性流变。在更短时间尺度上，两种模式通过数值效率较高的弹性波机制完成调整。这种弹性波修改保留了主要物理过程，并产生完全显式的数值方案，大幅提高计算效率。rEVP 也是完全显式的，其设计目标是收敛到 VP 解。

EVP 海冰动力学详见原文所引 Hunke 1997、2001、2002、2003；EAP 详见 Tsamados 2013。原文所引 Hunke 1999 和 Tsamados 2013 分别比较了 EVP、EAP 与 VP 的模拟结果及性能，并在真实北极模拟中进行了相互比较。本版代码的 EVP 数值实现依据 Hunke 2002、Hunke 2003，并按 Bouillon 2013 修订求解器。rEVP 细节见 Lemieux 2012、Bouillon 2013、Kimmritz 2015 和 Koldunov 2019；CICE 的 EAP 实现详见 Tsamados 2013。

VP 求解器基本遵循 Lemieux 2008，以 FGMRES（原文引用 Saad 1993）为线性求解器，以 GMRES 为预条件器。VP 求解器尚未在 `tx1` 网格上测试。B 网格支持 EVP、rEVP、EAP 和 VP；目前 C 网格仅支持 EVP 和 rEVP。

动力学对面积密集度大于 `dyn_area_min`、质量大于 `dyn_mass_min` 的单元求解。这两个阈值可通过 namelist 设置。较低阈值可使含少量海冰的单元也参与计算，改善解，但会增加开销，也可能导致不稳定。因此代码和基础 namelist 默认值针对 B 网格设置，C 网格测试使用不同值。下文概述方程，细节请参阅上述文献。

## 动量时间步推进

### EVP 时间离散与求解

经典 EVP 方法对动量方程进行以下时间离散。代码中定义 $\texttt{vrel}=a_ic_w\rho_w|\mathbf U_w-\mathbf u^k|$，以及 $C_b=T_b(\sqrt{(u^k)^2+(v^k)^2}+u_0)^{-1}$；$k$ 为子循环（subcycling）步。下式也定义了代码中的其他变量：

$$
\begin{aligned}
\underbrace{\left(\frac m{\Delta t_e}+\texttt{vrel}\cos\theta+C_b\right)}_{\texttt{cca}}u^{k+1}
-\underbrace{(mf\pm\texttt{vrel}\sin\theta)}_{\texttt{ccb}}v^l
={}&\underbrace{\frac{\partial\sigma_{1j}^{k+1}}{\partial x_j}}_{\texttt{strintx}}
+\underbrace{\left(\tau_{ax}-mg\frac{\partial H_\circ}{\partial x}\right)}_{\texttt{forcex}}\\
&+\texttt{vrel}\underbrace{(U_w\cos\theta\mp V_w\sin\theta)}_{\texttt{waterx}}
+\frac m{\Delta t_e}u^k,
\end{aligned}
$$

$$
\begin{aligned}
\underbrace{(mf\pm\texttt{vrel}\sin\theta)}_{\texttt{ccb}}u^l
+\underbrace{\left(\frac m{\Delta t_e}+\texttt{vrel}\cos\theta+C_b\right)}_{\texttt{cca}}v^{k+1}
={}&\underbrace{\frac{\partial\sigma_{2j}^{k+1}}{\partial x_j}}_{\texttt{strinty}}
+\underbrace{\left(\tau_{ay}-mg\frac{\partial H_\circ}{\partial y}\right)}_{\texttt{forcey}}\\
&+\texttt{vrel}\underbrace{(\pm U_w\sin\theta+V_w\cos\theta)}_{\texttt{watery}}
+\frac m{\Delta t_e}v^k.
\end{aligned}
$$

这里 $\texttt{vrel}\cdot\texttt{waterx(y)}=\texttt{taux(y)}$，$u^l$、$v^l$ 的定义随网格而异。B 网格的 $u$、$v$ 共点，因此 $u^l=u^{k+1}$、$v^l=v^{k+1}$。令 $\mathbf F=\nabla\cdot\boldsymbol\sigma^{k+1}$，定义：

$$
\hat u=F_u+\tau_{ax}-mg\frac{\partial H_\circ}{\partial x}
+\texttt{vrel}(U_w\cos\theta\mp V_w\sin\theta)+\frac m{\Delta t_e}u^k,
$$

$$
\hat v=F_v+\tau_{ay}-mg\frac{\partial H_\circ}{\partial y}
+\texttt{vrel}(\pm U_w\sin\theta+V_w\cos\theta)+\frac m{\Delta t_e}v^k.
$$

于是两分量方程为：

$$
\begin{aligned}
au^{k+1}-bv^{k+1}&=\hat u,\\
bu^{k+1}+av^{k+1}&=\hat v,
\end{aligned}
\qquad
a=\frac m{\Delta t_e}+\texttt{vrel}\cos\theta+C_b,
\quad b=mf\pm\texttt{vrel}\sin\theta.
$$

同时求解得到：

$$
u^{k+1}=\frac{a\hat u+b\hat v}{a^2+b^2},
\qquad
v^{k+1}=\frac{a\hat v-b\hat u}{a^2+b^2}.
$$

EAP 的时间离散与求解方法和 B 网格 EVP 完全相同，更多细节见下文“弹性各向异性塑性”。C 网格的 $u$、$v$ 不共点。求 E 点的 $u^{k+1}$ 时，取 $v^l=v^k_{int}$，即把周围 N 点的 $v^k$ 插值到 E 点；求 $v$ 时同理。以显式方式处理非对角项（原文引用 Kimmritz 2016），得到：

$$
u^{k+1}=\frac{\hat u+bv^k_{int}}a,
\qquad
v^{k+1}=\frac{\hat v-bu^k_{int}}a.
$$

### 修订版 EVP 时间离散与求解

修订版 EVP 基于伪时间迭代（pseudo-time iteration；原文引用 Lemieux 2012、Bouillon 2013、Kimmritz 2015）。只要数值参数合适且迭代次数足够大，按设计它应收敛到 VP 解。为此，惯性项写成与隐式求解器的后向欧拉形式相同，并额外加入伪时间迭代项。离散后的动量方程为：

$$
\begin{aligned}
\frac{\beta^*(u^{k+1}-u^k)}{\Delta t_e}
+\frac{m(u^{k+1}-u^n)}{\Delta t}
+(\texttt{vrel}\cos\theta+C_b)u^{k+1}
-(mf\pm\texttt{vrel}\sin\theta)v^l
={}&\frac{\partial\sigma_{1j}^{k+1}}{\partial x_j}
+\tau_{ax}-mg\frac{\partial H_\circ}{\partial x}
+\texttt{vrel}(U_w\cos\theta\mp V_w\sin\theta),\\
\frac{\beta^*(v^{k+1}-v^k)}{\Delta t_e}
+\frac{m(v^{k+1}-v^n)}{\Delta t}
+(\texttt{vrel}\cos\theta+C_b)v^{k+1}
+(mf\pm\texttt{vrel}\sin\theta)u^l
={}&\frac{\partial\sigma_{2j}^{k+1}}{\partial x_j}
+\tau_{ay}-mg\frac{\partial H_\circ}{\partial y}
+\texttt{vrel}(\pm U_w\sin\theta+V_w\cos\theta).
\end{aligned}
$$

$\beta^*$ 是数值参数，$u^n$、$v^n$ 是上一时间层解的分量。设 $\beta=\beta^*\Delta t/(m\Delta t_e)$（原文引用 Bouillon 2013），可写成与经典 EVP 对应的形式：

$$
\begin{aligned}
\underbrace{\left((\beta+1)\frac m{\Delta t}+\texttt{vrel}\cos\theta+C_b\right)}_{\texttt{cca}}u^{k+1}
-\underbrace{(mf\pm\texttt{vrel}\sin\theta)}_{\texttt{ccb}}v^l
={}&\underbrace{\frac{\partial\sigma_{1j}^{k+1}}{\partial x_j}}_{\texttt{strintx}}
+\underbrace{\left(\tau_{ax}-mg\frac{\partial H_\circ}{\partial x}\right)}_{\texttt{forcex}}\\
&+\texttt{vrel}\underbrace{(U_w\cos\theta\mp V_w\sin\theta)}_{\texttt{waterx}}
+\frac m{\Delta t}(\beta u^k+u^n),\\
\underbrace{(mf\pm\texttt{vrel}\sin\theta)}_{\texttt{ccb}}u^l
+\underbrace{\left((\beta+1)\frac m{\Delta t}+\texttt{vrel}\cos\theta+C_b\right)}_{\texttt{cca}}v^{k+1}
={}&\underbrace{\frac{\partial\sigma_{2j}^{k+1}}{\partial x_j}}_{\texttt{strinty}}
+\underbrace{\left(\tau_{ay}-mg\frac{\partial H_\circ}{\partial y}\right)}_{\texttt{forcey}}\\
&+\texttt{vrel}\underbrace{(\pm U_w\sin\theta+V_w\cos\theta)}_{\texttt{watery}}
+\frac m{\Delta t}(\beta v^k+v^n).
\end{aligned}
$$

此后，B 网格和 C 网格上的 $u^{k+1}$、$v^{k+1}$ 按经典 EVP 的相同方法求解。

### 隐式 VP 时间离散与求解

VP 方法以**后向欧拉法**（Backward Euler）隐式离散动量方程，不显式计算应力：

$$
\begin{aligned}
m\frac{u^n-u^{n-1}}{\Delta t}
&=\frac{\partial\sigma_{1j}^n}{\partial x_j}-\tau_{w,x}^n+\tau_{b,x}^n+mfv^n+r_x^n,\\
m\frac{v^n-v^{n-1}}{\Delta t}
&=\frac{\partial\sigma_{2j}^n}{\partial x_j}-\tau_{w,y}^n+\tau_{b,y}^n-mfu^n+r_y^n.
\end{aligned}
$$

$\mathbf r=(r_x,r_y)$ 包含不依赖 $u^n$、$v^n$ 的项，即海面倾斜和风应力。水拖曳、海底应力和流变项都依赖速度场，因此未知量只有 $u^n$、$v^n$。空间离散后，得到 $N$ 个未知量对应的 $N$ 个非线性方程，可简写为：

$$
\mathbf A(\mathbf u)\mathbf u=\mathbf b(\mathbf u).
$$

这里省略时间层下标 $n$。$\mathbf A$ 是 $N\times N$ 矩阵，$\mathbf u$、$\mathbf b$ 是长度为 $N$ 的向量。$\mathbf u$ 由离散冰速的所有 $u$ 分量后接所有 $v$ 分量组成。由于水应力、海底应力及部分流变项对 $\mathbf u$ 非线性依赖，$\mathbf b$ 也是速度向量的函数。

非线性系统通过 Picard 迭代求解。以上一迭代值 $\mathbf u_{k-1}$ 代入 $\mathbf A$ 和 $\mathbf b$，将系统线性化：

$$
\mathbf A(\mathbf u_{k-1})\mathbf u_k=\mathbf b(\mathbf u_{k-1}).
$$

得到的线性系统使用灵活广义最小残量法（Flexible Generalized Minimum RESidual，FGMRES；原文引用 Saad 1993）求解，并重复迭代。Namelist 标志 `maxits_nonlin` 设置 Picard 最大迭代次数，`reltol_nonlin` 设置相对容差。原文给出的停止条件为 $\lVert\mathbf u_k\rVert_2<\texttt{reltol\_nonlin}\lVert\mathbf u_0\rVert_2$，或达到 `maxits_nonlin`。FGMRES 及预条件器的参数可通过其他 namelist 标志控制，见[动力学 namelist](../user_guide/ug_case_settings.md)。

## 表面应力项

风应力的形式见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。以下介绍海冰—海洋应力及海底应力。

### 海冰—海洋应力

每个热力学时间步末，须根据 `taux(y)` 和动量方程左侧包含 `vrel` 的项构造海冰—海洋应力。水应力计算中 $\pm\texttt{vrel}\sin\theta$ 项的符号取决于南北半球。Hibler–Bryan 形式的海冰—海洋应力（原文引用 Hibler 1987）包含在 `ice_dyn_shared.F90` 中，但尚待进一步测试，因此目前被注释掉。

### 海底应力

CICE 提供两种海底应力计算方法。海底应力是动量方程中表示触底冰脊与海床相互作用的项。将 namelist 中 `seabed_stress` 设为真可启用。`seabed_stress_method='LKD'` 选择原文所引 Lemieux 2016 的海底应力（或底部应力）参数化；设为 `'probabilistic'` 则使用基于冰与海底接触概率的方法。

两种方案都把海底应力分量写成 $\tau_{bx}=C_bu$、$\tau_{by}=C_bv$，其中 $C_b$ 为海底应力系数；它们的差别在于 $C_b$ 的计算方式。用户须提供水深地形场（bathymetry field）。建议该场的水深大于 5 m，并能准确描述拉普捷夫海和东西伯利亚海等水深不足 30 m 的浅海区。

**基于冰脊吃水深度线性关系（linear keel draft，LKD）的海底应力。**该方案假定最大冰脊吃水深度随网格单元平均厚度（即海冰体积）线性变化：

$$
C_b=k_2\max[0,h-h_c]e^{-\alpha_b(1-a)}
(\sqrt{u^2+v^2}+u_0)^{-1}.
$$

$k_2$ 决定参数化的触底冰脊可承受的最大海底应力；$u_0$ 是很小的剩余速度；$\alpha_b$ 保证冰密集度低于 1 时海底应力迅速下降。代码把 $k_2\max[0,h-h_c]e^{-\alpha_b(1-a)}$ 定义为 $T_b$。

在 B 网格上，$h$、$a$、$h_c$ 在 U 点计算，分别记为 $h_u$、$a_u$、$h_{cu}$：

$$
\begin{aligned}
h_u&=\max[v_i(i,j),v_i(i+1,j),v_i(i,j+1),v_i(i+1,j+1)],\\
a_u&=\max[a_i(i,j),a_i(i+1,j),a_i(i,j+1),a_i(i+1,j+1)],\\
h_{cu}&=a_uh_{wu}/k_1.
\end{aligned}
$$

$a_i$、$v_i$ 是 U 点 $(i,j)$ 周围的总冰密集度和冰体积。参数 $k_1$ 定义临界冰厚 $h_{cu}$：当水深 $h_{wu}=\min[h_w(i,j),h_w(i+1,j),h_w(i,j+1),h_w(i+1,j+1)]$ 时，冰脊达到海底。根据 $C_b$ 的形式，只有 $h_u>h_{cu}$ 时海底应力分量才非零。

C 网格的 $u$、$v$ 不共点，因此分别在 E 点和 N 点计算 $T_b$。以 E 点为例：

$$
\begin{aligned}
h_e&=\max[v_i(i,j),v_i(i+1,j)],\\
a_e&=\max[a_i(i,j),a_i(i+1,j)],\\
h_{ce}&=a_eh_{we}/k_1,
\end{aligned}
$$

其中 $h_{we}=\min[h_w(i,j),h_w(i+1,j)]$；N 点采用类似计算。为了防止不真实的触底，当 $h_{wu}>30$ m 时将 $T_b$ 设为零；C 网格根据 $h_{we}$、$h_{wn}$ 作相同处理。30 m 上限依据北冰洋大型冰脊的观测资料（原文引用 Amundrud 2004）。

最大海底应力取决于冰脊超出静水平衡的重量及 $k_2$，但对模拟岸冰（landfast ice）范围影响最显著的是 $k_1$；它可通过 namelist 变量 `k1` 在运行时修改。

**基于概率方法的海底应力。**这种更复杂的触底参数化，根据冰厚分布（ITD）与海底接触的概率计算海底应力（原文引用 Dupont 2022）。CICE 等多冰厚类别模式通常只有 5–10 个厚度类别；这种较粗的 ITD 表示无法解析其尾部，而尾部对触底事件至关重要。

为表示分布尾部，模拟的 ITD 被转换为正偏态概率函数 $f(x)$，其中 $x$ 为海冰厚度。新分布的均值和方差与原 ITD 相同，$f(x)$ 取对数正态分布。假设 T 点的水深 $y$ 服从正态分布 $b(y)$。$b(y)$ 的均值来自用户提供的水深场，标准差 $\sigma_b$ 当前固定为 2.5 m。今后可用高分辨率水深数据指定分布，并考虑海面高度变化带来的水深变化。

假设静水平衡且忽略积雪影响，厚度为 $x$ 的浮冰吃水深度为 $D(x)=\rho_ix/\rho_w$，$\rho_i$ 为海冰密度。ITD 与海底的接触概率为：

$$
P_c=\int_0^\infty\int_0^{D(x)}g(x)b(y)\,dy\,dx.
$$

首先在 T 点计算 $T_b$，记为 $T_{bt}$，它取决于冰脊超出静水平衡的重量。参数化先计算：

$$
T_{bt}^*=\mu_sg\int_0^\infty\int_0^{D(x)}
(\rho_ix-\rho_wy)g(x)b(y)\,dy\,dx,
$$

再将 $T_{bt}^*$ 乘以 $e^{-\alpha_b(1-a_i)}$ 得到 $T_{bt}$，类似 LKD 方法。

计算 $T_{bt}^*$ 时，用大量小类别（100 个）离散 $f(x)$、$b(y)$。$f(x)$ 在 0–50 m 之间离散；$b(y)$ 在均值上下各三个 $\sigma_b$ 处截断。$f(x)$ 还会在对数正态分布的某一分位数之后设为零。该分位数目前为 99.7%，显著影响岸冰模拟，并用作调参量，其作用类似 LKD 的 $k_1$。

B 网格 U 点的 $T_b$ 由其周围 T 点值计算：

$$
T_{bu}=\max[T_{bt}(i,j),T_{bt}(i+1,j),T_{bt}(i,j+1),T_{bt}(i+1,j+1)].
$$

沿用 LKD 方法，海底应力系数最终为：

$$
C_b=T_{bu}(\sqrt{u^2+v^2}+u_0)^{-1}.
$$

C 网格分别在 E、N 点计算：

$$
T_{be}=\max[T_{bt}(i,j),T_{bt}(i+1,j)],
\qquad
T_{bn}=\max[T_{bt}(i,j),T_{bt}(i,j+1)].
$$

相应的 $C_b$ 分别为 $T_{be}(\sqrt{u^2+v_{int}^2}+u_0)^{-1}$ 和 $T_{bn}(\sqrt{u_{int}^2+v^2}+u_0)^{-1}$；$v_{int}$ 是插值到 E 点的 $v$，$u_{int}$ 是插值到 N 点的 $u$。

## 流变

为方便计算，将应力张量 $\boldsymbol\sigma$ 表示为 $\sigma_1=\sigma_{11}+\sigma_{22}$（代码中的 `stressp`）和 $\sigma_2=\sigma_{11}-\sigma_{22}$（`stressm`）。定义辐散应变率 $D_D$、水平拉伸应变率 $D_T$ 和剪切应变率 $D_S$：

$$
D_D=\dot\epsilon_{11}+\dot\epsilon_{22},
\qquad
D_T=\dot\epsilon_{11}-\dot\epsilon_{22},
\qquad
D_S=2\dot\epsilon_{12},
$$

其中 $\dot\epsilon_{ij}=\tfrac12(\partial u_i/\partial x_j+\partial u_j/\partial x_i)$。注意 $\sigma_1$、$\sigma_2$ 不要与归一化主应力 $\sigma_{n,1}$、$\sigma_{n,2}$（`sig1`、`sig2`）混淆；后者定义为：

$$
\sigma_{n,1},\sigma_{n,2}=\frac1P\left(\frac{\sigma_1}{2}
\pm\sqrt{\left(\frac{\sigma_2}{2}\right)^2+\sigma_{12}^2}\right),
$$

其中 $P$ 是海冰强度。除归一化主应力外，CICE 还能输出海冰内部压力（internal ice pressure），这是支持冰区航行的重要场。内部压力 `sigP` 等于法向应力 $\sigma_{11}$、$\sigma_{22}$ 的平均值乘以 $-1$，即 $-\sigma_1/2$。

### 黏塑性

VP 本构律（constitutive law）为：

$$
\sigma_{ij}=2\eta\dot\epsilon_{ij}+(\zeta-\eta)D_D-P_R\frac{\delta_{ij}}2.
$$

$\eta$、$\zeta$ 分别为体黏度和剪切黏度；$P_R$ 为“替代压力”（replacement pressure，见原文引用的 Geiger 1998），用于防止应变率恰好为零时，海冰强度 $P$ 的空间变化仍引起残余冰运动。

方案使用椭圆屈服曲线（elliptical yield curve），黏度为：

$$
\zeta=\frac{P(1+k_t)}{2\Delta},
\qquad
\eta=e_g^{-2}\zeta,
\qquad
\Delta=\left[D_D^2+\frac{e_f^2}{e_g^4}(D_T^2+D_S^2)\right]^{1/2}.
$$

当变形量 $\Delta$ 趋于零，黏度趋于无穷。为避免此问题，计算 $\zeta$ 时用受限的 $\Delta^*$ 代替 $\Delta$。代码提供两种限制 $\Delta$（或给黏度设上限）的方法。`capping_method='max'` 时，$\Delta^*=\max(\Delta,\Delta_{min})$（原文引用 Hibler 1979）；设为 `'sum'` 时，使用较平滑的 $\Delta^*=\Delta+\Delta_{min}$（原文引用 Kreyscher 2000）。海冰强度 $P$ 是冰厚分布的函数，见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。

标准 Hibler 1979 VP 流变还有两项可选修改。第一，依据原文所引 Konig 2010 和 Lemieux 2016，可修改椭圆屈服曲线，使海冰具有各向同性抗拉强度。抗拉强度写为 $k_tP$，其中 $0\le k_t\le1$；可通过 namelist 参数 `Ktens` 在运行时修改。

第二，$e_f$ 是椭圆屈服曲线的长短轴之比，而 $e_g$ 刻画塑性势（plastic potential）：另一条椭圆，用于将流动法则与屈服曲线解耦（原文引用 Ringeisen 2021）。代码中分别称为 `e_yieldcurve` 和 `e_plasticpot`，可在 namelist 中设置。塑性势可以让线性运动学特征（linear kinematic features）的裂缝角度更真实。Ringeisen 2021 建议 $e_f>1$ 且 $e_g<e_f$。默认值 $e_f=e_g=2$、$k_t=0$ 对应标准 VP 流变。

代码提供四种 VP 动量方程求解方式：标准 EVP、一维 EVP 求解器、修订版 EVP 和隐式 Picard 求解器。这四种方法都可选择前述黏度限制方法，以及屈服曲线和流动法则的修改；但选择 C 网格时，目前只能使用 EVP 和修订版 EVP。

### 弹性黏塑性

EVP 模式通过 VP 本构律的正则化形式确定内部应力张量：

$$
\frac1E\frac{\partial\sigma_1}{\partial t}+\frac{\sigma_1}{2\zeta}+\frac{P_R}{2\zeta}=D_D,
$$

$$
\frac1E\frac{\partial\sigma_2}{\partial t}+\frac{\sigma_2}{2\eta}=D_T,
\qquad
\frac1E\frac{\partial\sigma_{12}}{\partial t}+\frac{\sigma_{12}}{2\eta}=\frac12D_S.
$$

黏度在子循环中更新，因此整个动力学部分在一个时间步内进行子循环。弹性参数 $E$ 由弹性波的阻尼时间尺度 $T$ 定义，满足 $\Delta t_e<T<\Delta t$，并有：

$$
E=\frac\zeta T,
\qquad T=E_\circ\Delta t,
$$

其中 $E_\circ$（`elasticDamp`）是小于 1 的可调参数。为改善数值收敛，采用原文所引 Bouillon 2013 对 $\sigma_2$、$\sigma_{12}$ 方程的修改后，应力方程成为：

$$
\begin{aligned}
\frac{\partial\sigma_1}{\partial t}+\frac{\sigma_1+P_R}{2T}&=\frac\zeta T D_D,\\
\frac{\partial\sigma_2}{\partial t}+\frac{\sigma_2}{2T}&=\frac\eta T D_T,\\
\frac{\partial\sigma_{12}}{\partial t}+\frac{\sigma_{12}}{2T}&=\frac\eta{2T}D_S.
\end{aligned}
$$

时间离散后为：

$$
\begin{aligned}
\frac{\sigma_1^{k+1}-\sigma_1^k}{\Delta t_e}
+\frac{\sigma_1^{k+1}+P_R^k}{2T}&=\frac{\zeta^k}{T}D_D^k,\\
\frac{\sigma_2^{k+1}-\sigma_2^k}{\Delta t_e}
+\frac{\sigma_2^{k+1}}{2T}&=\frac{\eta^k}{T}D_T^k,\\
\frac{\sigma_{12}^{k+1}-\sigma_{12}^k}{\Delta t_e}
+\frac{\sigma_{12}^{k+1}}{2T}&=\frac{\eta^k}{2T}D_S^k.
\end{aligned}
$$

$k$ 仍表示子循环步。左侧除 $P_R$ 外的系数均为常数。这一修改弥补了把黏度项纳入子循环所降低的效率。定义 $E$、$T$、$\Delta t_e$ 的参数选择见下文“修订版 EVP 方法”及相关参数说明。

在 B 网格上，$\sigma_1$、$\sigma_2$、$\sigma_{12}$ 共点，位于 U 点；计算这些应力所用的 $\zeta$、$\eta$ 和 $P_R$ 也定义在 U 点。C 网格上，$\sigma_1$、$\sigma_2$ 位于 T 点，$\sigma_{12}$ 位于 U 点。每个子循环步先在 T 点计算 $\zeta$、$\eta$ 和 $P_R$。为此，按原文所引 Bouillon 2013 的方法计算 $\Delta$（细节见 Kimmritz 2016）：先在 U 点计算 $D_S^2$，再插值到 T 点。由于 $\sigma_{12}$ 在 U 点计算，$\eta$ 也需在 U 点计算。若 namelist 中 `visc_method='avg_zeta'`（默认），将 T 点的 $\eta$ 插值到 U 点；这对应 Bouillon 2013 和 Kimmritz 2016 的 C1 配置。若 `visc_method='avg_strength'`，则把 T 点的强度 $P$ 插值到 U 点，并在 U 点计算 $\Delta$，再依据上述黏度方程得到 $\eta$；这对应 Kimmritz 2016 的 C2 配置。

### 一维 EVP 求解器

标准 EVP 求解器迭代数百次，每次迭代只执行少量计算，却需通过 MPI 通信，因此速度主要受通信限制，难以进一步优化。一维 EVP 求解器通过共享内存避免通信，不必调用 MPI 通信器，从而有望改善扩展性。它在共享内存上性能最好，也可在 MPI 或混合 MPI/OpenMP 配置中运行，但此时只在主处理器上执行。

地球物理模式的扩展性通常受内存使用限制。为优化这一点，一维 EVP 求解器仍求解上节相同的方程，但把所有矩阵转换为向量（一维数组），以更适应计算机硬件。向量化以及数组在内存中的连续布局使编译器更容易优化，并传递指针而不是复制向量。该求解器不支持三极网格；尝试这种组合时程序会中止。

### 修订版 EVP 方法

引入数值参数 $\alpha=2T/\Delta t_e$（原文引用 Bouillon 2013），前述时间离散的应力方程变为：

$$
\begin{aligned}
\alpha(\sigma_1^{k+1}-\sigma_1^k)+\sigma_1^k+P_R^k&=2\zeta^kD_D^k,\\
\alpha(\sigma_2^{k+1}-\sigma_2^k)+\sigma_2^k&=2\eta^kD_T^k,\\
\alpha(\sigma_{12}^{k+1}-\sigma_{12}^k)+\sigma_{12}^k&=\eta^kD_S^k.
\end{aligned}
$$

与经典 EVP 不同，每式第二项取迭代 $k$ 时的值（原文引用 Bouillon 2013）。此外，$\Delta t_e$ 与子循环次数（迭代次数）的乘积不必等于平流时间步 $\Delta t$。和经典 EVP 一样，应力由上一时间层的值初始化。将 namelist 参数 `revised_evp=true` 可启用该方法。代码中 $\alpha$ 对应 `arlx`，上文引入的 $\beta$ 对应 `brlx`；这两个值可在 namelist 中设置。建议取较大的值，并设置 $\alpha=\beta$（原文引用 Kimmritz 2015）。

### 弹性各向异性塑性

EAP 模式把内部应力张量与底层假想菱形冰块的几何性质及方向联系起来。与各向同性 EVP 流变不同，EAP 的各向异性塑性屈服曲线取决于菱形冰块的方向（下图中的单位向量 $\mathbf r$）相对形变率主方向的取向。海冰覆盖的局地各向异性由额外的预报变量——**结构张量**（structure tensor）$\mathbf A$——表示：

$$
\mathbf A=\int_{\mathbb S}\vartheta(\mathbf r)\mathbf r\mathbf r\,d\mathbf r.
$$

$\mathbb S$ 是单位半径圆，$\mathbf A$ 是迹为 1 的 $2\times2$ 矩阵。下文用结构张量描述冰块取向分布。为简化，取概率密度函数 $\vartheta(\mathbf r)$ 为高斯函数 $\vartheta(z)=\omega_1e^{-\omega_2z^2}$，其中 $z$ 是冰块相对优选排列轴 $x_1$ 的倾角。$\vartheta(z)$ 以 $\pi$ 为周期，正系数 $\omega_1$、$\omega_2$ 由归一化条件 $\int_0^{2\pi}\vartheta(z)\,dz=1$ 确定。$\mathbf A$ 的主分量比 $A_1/A_2$ 由结构张量的现象学演化方程得到：

$$
\frac{D\mathbf A}{Dt}=\mathbf F_{iso}(\mathbf A)+\mathbf F_{frac}(\mathbf A,\boldsymbol\sigma).
$$

$t$ 为时间，$D/Dt$ 是考虑平流和刚体转动的共转时间导数（co-rotational time derivative）：$D\mathbf A/Dt=d\mathbf A/dt-\mathbf W\cdot\mathbf A-\mathbf A\cdot\mathbf W^T$，$\mathbf W$ 为涡度张量。$\mathbf F_{iso}$ 描述热裂、融化、冰块重新冻结连接等使冰盖更趋各向同性的过程；$\mathbf F_{frac}$ 描述断裂造成的冰块重新取向，它显式依赖海冰应力，但不依赖应力大小。

依据原文所引 Wilchinsky 2006 和 Schulson 2001 的实验，北极海冰覆盖有四种破坏机制，由海冰应力主值 $\sigma_1$、$\sigma_2$ 的比值决定：（1）双轴拉伸时，裂缝沿垂直主轴形成，抵消冰块取向表观上的再分配；（2）只有一个主应力为压缩时，沿压缩方向轴向劈裂；（3）低围压比双轴压缩（$\sigma_1/\sigma_2<R$）时，海冰按库仑型破坏，通过沿最大压缩应力方向形成滑移线来界定新冰块；（4）高围压比双轴压缩（$\sigma_1/\sigma_2\ge R$）时，冰沿两个主方向破坏，累积方向效应相互抵消。

![相互嵌合的菱形冰块](../../source/science_guide/figures/EAP.png)

上图取自 Wilchinsky 2006。$\phi$ 是菱形锐角的一半，$L$ 为边长；$\boldsymbol n_1$、$\boldsymbol n_2$ 以及 $\boldsymbol\tau_1$、$\boldsymbol\tau_2$ 分别是沿菱形边缘的法向和切向单位向量。$\mathbf v=L\boldsymbol\tau_2\cdot\dot{\boldsymbol\epsilon}$ 是由向量 $L\boldsymbol\tau_2$ 连接的两冰块之间的相对速度。$\mathbf r$ 是沿菱形主对角线的单位向量。图中的菱形只表示所有可能方向中的一种实现。角度 $z$ 表示菱形主轴相对沿 $x_1$ 轴优选方向的旋转。

新各向异性流变除求解动量和应力方程外，还须求解结构张量的演化方程。该方程在 EVP 子循环中求解；与动量及应力演化方程一致，此处忽略结构张量的平流项。于是演化方程化为：

$$
\frac{\partial A_{11}}{\partial t}=-k_t\left(A_{11}-\frac12\right)+M_{11},
\qquad
\frac{\partial A_{12}}{\partial t}=-k_tA_{12}+M_{12}.
$$

右侧第一项对应各向同性贡献 $F_{iso}$，$M_{11}$、$M_{12}$ 为 $F_{frac}$ 的分量，详见 Wilchinsky 2006 和 Tsamados 2013。这些演化方程在时间上半隐式离散。各向异性程度由结构张量的最大特征值 $A_1$ 衡量，$A_2=1-A_1$。$A_1=1$ 表示冰块完全对齐，$A_1=0.5$ 表示方向均匀分布。虽然通过 $\phi$ 指定了菱形冰块的长宽比，并未假定菱形尺寸，因此理论在形式上与尺度无关。

如 Wilchinsky 2006 所详述，给定冰块单一取向、平均冰厚 $h$ 时，内部冰应力可以显式计算，并分为压力脊化（ridging，r）和滑动（sliding，s）贡献：

$$
\boldsymbol\sigma^b(\mathbf r,h)
=P_r(h)\boldsymbol\sigma_r^b(\mathbf r)
+P_s(h)\boldsymbol\sigma_s^b(\mathbf r).
$$

$P_r$、$P_s$ 分别为压力脊化和滑动强度。相应应力取决于 $\theta=\arctan(\dot\epsilon_{II}/\dot\epsilon_I)$、应变率张量主轴与结构张量之间的角度 $y$（图中的 $x_1$ 轴），以及图中定义的 $z$。上式假定底层冰块相互平行；但连续介质尺度海冰区域中，不同地点的冰块可能有不同取向，因此一组冰块上的平均应力为：

$$
\boldsymbol\sigma^{EAP}(h)=P_r(h)\int_{\mathbb S}\vartheta(\mathbf r)
\left[\boldsymbol\sigma_r^b(\mathbf r)+k\boldsymbol\sigma_s^b(\mathbf r)\right]d\mathbf r,
$$

其中摩擦参数 $k=P_s/P_r$，压力脊化强度 $P_r(h)$ 对应前述 EVP 框架中的冰强度 $P$。

和 EVP 一样，EAP 引入弹性并非为了描述某种物理效应，而是为了利用求解完整海冰动量平衡的高效显式数值算法。EAP 的应力方程为：

$$
\frac{\partial\sigma_1}{\partial t}+\frac{\sigma_1}{2T}=\frac{\sigma_1^{EAP}}{2T},
\quad
\frac{\partial\sigma_2}{\partial t}+\frac{\sigma_2}{2T}=\frac{\sigma_2^{EAP}}{2T},
\quad
\frac{\partial\sigma_{12}}{\partial t}+\frac{\sigma_{12}}{2T}=\frac{\sigma_{12}^{EAP}}{2T}.
$$

对当前应变率和结构张量，使用查找表定义各向异性应力 $\boldsymbol\sigma^{EAP}$。该表通过对结构张量最大特征值 $1/2\le A_1\le1$、角度 $0\le\theta\le2\pi$，以及应变率张量主轴与结构张量之间的角度 $-\pi/2\le y\le\pi/2$ 取离散值，计算按强度归一化的应力而建立（原文引用 Tsamados 2013）。弹性弛豫后的应力传给动量方程，随后在 EVP 子循环中按常规方式更新海冰速度。结构张量演化方程以与冰速和内部应力相同的频率 $\Delta t_e$ 隐式求解。最后，为与新流变保持一致，压力脊化造成的面积损失率计算为 $|\dot{\boldsymbol\epsilon}|\alpha_r(\theta)$，其中：

$$
\alpha_r(\theta)=\frac{\sigma_{ij}^r\dot\epsilon_{ij}}{P_r|\dot{\boldsymbol\epsilon}|},
\qquad
\alpha_s(\theta)=\frac{\sigma_{ij}^s\dot\epsilon_{ij}}{P_s|\dot{\boldsymbol\epsilon}|}.
$$

压力脊化速率与海冰强度均在动力学外层循环中计算。

原文：[sg_dynamics.rst](../../source/science_guide/sg_dynamics.rst)
